defmodule Mix.Tasks.Sonos.Check do
  use Mix.Task

  alias Sonosex.Speaker
  alias Sonosex.UPnP.AVTransport

  @shortdoc "Quick health check across all Sonos speakers"

  def run(_args) do
    speakers = Mix.Tasks.Sonos.ensure_discovery()

    case speakers do
      [] ->
        Mix.shell().error("No speakers found.")

      speakers ->
        Mix.shell().info("=== Speaker Health Check (#{length(speakers)} speakers) ===\n")

        speakers
        |> Enum.group_by(& &1.group_id)
        |> Enum.each(fn {_group_id, members} ->
          coordinator = Enum.find(members, &Speaker.coordinator?/1)
          coordinator_name = if coordinator, do: coordinator.name, else: "unknown"

          Mix.shell().info("Group: #{coordinator_name}")

          Enum.each(members, fn speaker ->
            role = if Speaker.coordinator?(speaker), do: "coord", else: "member"
            {state, status} = get_transport(speaker.ip)
            flag = if status not in ["OK", nil], do: " <<<", else: ""

            Mix.shell().info(
              "  #{speaker.name} (#{speaker.ip}) #{role} | #{state} | #{status}#{flag}"
            )
          end)

          Mix.shell().info("")
        end)

        unreachable =
          speakers
          |> Enum.filter(fn s ->
            case AVTransport.get_transport_info(s.ip) do
              {:error, _} -> true
              _ -> false
            end
          end)

        if unreachable != [] do
          Mix.shell().info("--- Unreachable speakers ---")

          Enum.each(unreachable, fn s ->
            Mix.shell().error("  #{s.name} (#{s.ip})")
          end)
        end

        versions = get_firmware_versions(speakers)

        if map_size(versions) > 1 do
          Mix.shell().info("--- Firmware versions ---")

          Enum.each(versions, fn {version, names} ->
            Mix.shell().info("  #{version}: #{Enum.join(names, ", ")}")
          end)
        end
    end
  end

  defp get_transport(ip) do
    case AVTransport.get_transport_info(ip) do
      {:ok, data} -> {data["CurrentTransportState"], data["CurrentTransportStatus"]}
      {:error, reason} -> {"ERROR", inspect(reason)}
    end
  end

  defp get_firmware_versions(speakers) do
    speakers
    |> Enum.reduce(%{}, fn speaker, acc ->
      case Sonosex.UPnP.DeviceProperties.get_zone_info(speaker.ip) do
        {:ok, data} ->
          version = data["DisplaySoftwareVersion"] || data["SoftwareVersion"] || "unknown"
          Map.update(acc, version, [speaker.name], &[speaker.name | &1])

        {:error, _} ->
          Map.update(acc, "unreachable", [speaker.name], &[speaker.name | &1])
      end
    end)
  end
end
