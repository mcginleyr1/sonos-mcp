defmodule Sonosex.Discovery do
  use GenServer
  require Logger

  alias Sonosex.Speaker
  alias Sonosex.UPnP.ZoneGroupTopology

  @multicast_addr {239, 255, 255, 250}
  @multicast_port 1900
  @discover_interval :timer.seconds(60)
  @recv_timeout 3_000

  @msearch_packet [
    "M-SEARCH * HTTP/1.1\r\n",
    "HOST: 239.255.255.250:1900\r\n",
    "MAN: \"ssdp:discover\"\r\n",
    "MX: 3\r\n",
    "ST: urn:schemas-upnp-org:device:ZonePlayer:1\r\n",
    "\r\n"
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list, do: GenServer.call(__MODULE__, :list)

  def find_by_name(name) do
    GenServer.call(__MODULE__, {:find_by_name, name})
  end

  def resolve_coordinator(speaker_name) do
    GenServer.call(__MODULE__, {:resolve_coordinator, speaker_name})
  end

  def refresh, do: GenServer.cast(__MODULE__, :refresh)

  @impl true
  def init(_opts) do
    send(self(), :discover)
    {:ok, %{speakers: %{}}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state.speakers), state}
  end

  def handle_call({:find_by_name, name}, _from, state) do
    result =
      state.speakers
      |> Map.values()
      |> Enum.find(fn s -> String.downcase(s.name || "") == String.downcase(name) end)

    case result do
      nil -> {:reply, {:error, :not_found}, state}
      speaker -> {:reply, {:ok, speaker}, state}
    end
  end

  def handle_call({:resolve_coordinator, speaker_name}, _from, state) do
    speakers = Map.values(state.speakers)

    with {:ok, speaker} <- find_speaker_by_name(speakers, speaker_name),
         {:ok, coordinator} <- find_coordinator(speakers, speaker) do
      {:reply, {:ok, coordinator}, state}
    else
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_cast(:refresh, state) do
    send(self(), :discover)
    {:noreply, state}
  end

  @impl true
  def handle_info(:discover, state) do
    speakers = do_discover()
    schedule_discover()
    {:noreply, %{state | speakers: speakers}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp do_discover do
    case ssdp_discover() do
      {:ok, ips} when ips != [] ->
        Logger.info("SSDP found #{length(ips)} Sonos speaker(s): #{Enum.join(ips, ", ")}")

        case fetch_zone_topology(ips) do
          groups when is_list(groups) and groups != [] ->
            build_speakers_from_topology(groups)

          _ ->
            Logger.warning("Zone topology failed, falling back to status info discovery")
            build_speakers_from_status(ips)
        end

      {:ok, []} ->
        Logger.info("No Sonos speakers found via SSDP")
        %{}

      {:error, _} ->
        %{}
    end
  end

  defp ssdp_discover do
    udp_opts = [:binary, active: false, multicast_if: {0, 0, 0, 0}, multicast_ttl: 4, reuseaddr: true]

    case :gen_udp.open(0, udp_opts) do
      {:ok, socket} ->
        :gen_udp.send(socket, @multicast_addr, @multicast_port, IO.iodata_to_binary(@msearch_packet))
        ips = recv_loop(socket, MapSet.new())
        :gen_udp.close(socket)
        {:ok, MapSet.to_list(ips)}

      {:error, reason} ->
        Logger.warning("Failed to open UDP socket for SSDP: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp recv_loop(socket, ips) do
    case :gen_udp.recv(socket, 0, @recv_timeout) do
      {:ok, {_addr, _port, packet}} ->
        case extract_sonos_ip(packet) do
          {:ok, ip} -> recv_loop(socket, MapSet.put(ips, ip))
          :skip -> recv_loop(socket, ips)
        end

      {:error, :timeout} ->
        ips
    end
  end

  defp extract_sonos_ip(packet) do
    is_sonos =
      String.contains?(packet, "ZonePlayer") or
        String.contains?(packet, "Sonos")

    if is_sonos do
      case Regex.run(~r/LOCATION:\s*http:\/\/([^:]+):1400/i, packet) do
        [_, ip] -> {:ok, ip}
        _ -> :skip
      end
    else
      :skip
    end
  end

  defp fetch_zone_topology([]), do: []

  defp fetch_zone_topology([ip | rest]) do
    case ZoneGroupTopology.get_state(ip) do
      {:ok, %{"ZoneGroupState" => xml}} when is_binary(xml) and xml != "" ->
        ZoneGroupTopology.parse_zone_groups(xml)

      {:ok, resp} ->
        Logger.debug("Unexpected topology response from #{ip}: #{inspect(Map.keys(resp))}")
        fetch_zone_topology(rest)

      {:error, reason} ->
        Logger.debug("Topology error from #{ip}: #{inspect(reason)}")
        fetch_zone_topology(rest)
    end
  end

  defp build_speakers_from_topology(zone_groups) do
    member_lookup =
      for group <- zone_groups,
          member <- group.members,
          into: %{} do
        {member.uuid, {member, group}}
      end

    topology_ips = for {_, {member, _}} <- member_lookup, do: member.ip

    status_infos =
      topology_ips
      |> Task.async_stream(&fetch_status_info/1, timeout: 5_000, on_timeout: :kill_task)
      |> Enum.flat_map(fn
        {:ok, {:ok, ip, info}} -> [{ip, info}]
        _ -> []
      end)
      |> Map.new()

    for {uuid, {member, group}} <- member_lookup, into: %{} do
      status = Map.get(status_infos, member.ip, %{})

      speaker = %Speaker{
        ip: member.ip,
        name: member.name,
        uuid: uuid,
        model: Map.get(status, "modelDisplayName", Map.get(status, "modelName")),
        group_id: group.group_id,
        coordinator_uuid: group.coordinator_uuid,
        household_id: Map.get(status, "householdId")
      }

      {uuid, speaker}
    end
  end

  defp build_speakers_from_status(ips) do
    ips
    |> Task.async_stream(&fetch_status_info/1, timeout: 5_000, on_timeout: :kill_task)
    |> Enum.flat_map(fn
      {:ok, {:ok, ip, info}} -> [{ip, info}]
      _ -> []
    end)
    |> Enum.map(fn {ip, info} ->
      uuid = Map.get(info, "serialNumber", ip)

      speaker = %Speaker{
        ip: ip,
        name: Map.get(info, "zoneName", ip),
        uuid: uuid,
        model: Map.get(info, "modelDisplayName", Map.get(info, "modelName")),
        group_id: Map.get(info, "groupId"),
        coordinator_uuid: nil,
        household_id: Map.get(info, "householdId")
      }

      {uuid, speaker}
    end)
    |> Map.new()
  end

  defp fetch_status_info(ip) do
    case Req.get("http://#{ip}:1400/status/info", receive_timeout: 3_000, connect_options: [timeout: 2_000]) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, ip, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, ip, decoded}
          _ -> {:error, :invalid_json}
        end

      _ ->
        {:error, :fetch_failed}
    end
  end

  defp find_speaker_by_name(speakers, name) do
    case Enum.find(speakers, fn s -> String.downcase(s.name || "") == String.downcase(name) end) do
      nil -> {:error, :not_found}
      speaker -> {:ok, speaker}
    end
  end

  defp find_coordinator(speakers, speaker) do
    case Enum.find(speakers, fn s -> s.uuid == speaker.coordinator_uuid end) do
      nil -> {:error, :coordinator_not_found}
      coordinator -> {:ok, coordinator}
    end
  end

  defp schedule_discover do
    Process.send_after(self(), :discover, @discover_interval)
  end
end
