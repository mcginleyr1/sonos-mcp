defmodule Mix.Tasks.Sonos.Diag do
  use Mix.Task

  alias Sonosex.{Speaker, Discovery}
  alias Sonosex.UPnP.{AVTransport, DeviceProperties}

  @shortdoc "Deep diagnostics for a single Sonos speaker"

  def run(args) do
    case args do
      [] ->
        Mix.shell().error("Usage: mix sonos.diag <speaker_name>")

      [name | _] ->
        Mix.Tasks.Sonos.ensure_discovery()

        case Discovery.find_by_name(name) do
          {:ok, speaker} -> print_diagnostics(speaker)
          {:error, :not_found} -> Mix.shell().error("Speaker '#{name}' not found.")
        end
    end
  end

  defp print_diagnostics(speaker) do
    ip = speaker.ip
    io = Mix.shell()

    io.info("=== Diagnostics: #{speaker.name} ===\n")

    io.info("-- Speaker --")
    io.info("Name:  #{speaker.name}")
    io.info("UUID:  #{speaker.uuid}")
    io.info("Model: #{speaker.model}")
    io.info("IP:    #{speaker.ip}")
    io.info("Group: #{speaker.group_id}")

    role =
      if Speaker.coordinator?(speaker),
        do: "Coordinator",
        else: "Member (coordinator: #{speaker.coordinator_uuid})"

    io.info("Role:  #{role}\n")

    io.info("-- Transport --")
    print_result(AVTransport.get_transport_info(ip), fn data ->
      io.info("State:  #{data["CurrentTransportState"]}")
      io.info("Status: #{data["CurrentTransportStatus"]}")
      io.info("Speed:  #{data["CurrentSpeed"]}")
    end)

    io.info("\n-- Position --")
    print_result(AVTransport.get_position_info(ip), fn data ->
      io.info("Track:    #{data["Track"]}")
      io.info("Position: #{data["RelTime"]} / #{data["TrackDuration"]}")
      io.info("URI:      #{data["TrackURI"]}")
    end)

    io.info("\n-- Media --")
    print_result(AVTransport.get_media_info(ip), fn data ->
      io.info("Queue size: #{data["NrTracks"]}")
      io.info("URI:        #{data["CurrentURI"]}")
      io.info("Medium:     #{data["PlayMedium"]}")
    end)

    io.info("\n-- Device Info --")
    print_result(DeviceProperties.get_zone_info(ip), fn data ->
      io.info("Software: #{data["DisplaySoftwareVersion"] || data["SoftwareVersion"]}")
      io.info("Hardware: #{data["HardwareVersion"]}")
      io.info("Serial:   #{data["SerialNumber"]}")
      io.info("MAC:      #{data["MACAddress"]}")
      io.info("IP:       #{data["IPAddress"]}")
    end)
  end

  defp print_result({:ok, data}, fun), do: fun.(data)
  defp print_result({:error, reason}, _fun), do: Mix.shell().error("Error: #{inspect(reason)}")
end
