defmodule Sonosex.MCP.Tools.Diagnostics do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  alias Sonosex.UPnP.{AVTransport, DeviceProperties}

  @impl EMCP.Tool
  def name, do: "sonos_diagnostics"

  @impl EMCP.Tool
  def description do
    "Get detailed diagnostics for a speaker: transport state, track info, firmware, IP, MAC. Useful for troubleshooting music drops."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"}
      },
      required: [:speaker_name]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    with_speaker(params, fn speaker ->
      ip = speaker.ip

      transport = AVTransport.get_transport_info(ip)
      position = AVTransport.get_position_info(ip)
      media = AVTransport.get_media_info(ip)
      zone_info = DeviceProperties.get_zone_info(ip)

      report = build_report(speaker, transport, position, media, zone_info)
      ok_response(report)
    end)
  end

  defp build_report(speaker, transport, position, media, zone_info) do
    sections = [
      "=== Diagnostics: #{speaker.name} ===",
      "",
      "-- Speaker --",
      "Name: #{speaker.name}",
      "UUID: #{speaker.uuid}",
      "Model: #{speaker.model}",
      "IP: #{speaker.ip}",
      "Group: #{speaker.group_id}",
      "Role: #{if Sonosex.Speaker.coordinator?(speaker), do: "Coordinator", else: "Member (coordinator: #{speaker.coordinator_uuid})"}",
      "",
      "-- Transport --",
      format_result(transport, fn data ->
        [
          "State: #{data["CurrentTransportState"]}",
          "Status: #{data["CurrentTransportStatus"]}",
          "Speed: #{data["CurrentSpeed"]}"
        ]
      end),
      "",
      "-- Position --",
      format_result(position, fn data ->
        [
          "Track: #{data["Track"]}",
          "Position: #{data["RelTime"]} / #{data["TrackDuration"]}",
          "URI: #{data["TrackURI"]}"
        ]
      end),
      "",
      "-- Media --",
      format_result(media, fn data ->
        [
          "Tracks in queue: #{data["NrTracks"]}",
          "Current URI: #{data["CurrentURI"]}",
          "Medium: #{data["PlayMedium"]}"
        ]
      end),
      "",
      "-- Device Info --",
      format_result(zone_info, fn data ->
        [
          "Software: #{data["DisplaySoftwareVersion"] || data["SoftwareVersion"]}",
          "Hardware: #{data["HardwareVersion"]}",
          "Serial: #{data["SerialNumber"]}",
          "MAC: #{data["MACAddress"]}",
          "IP: #{data["IPAddress"]}"
        ]
      end)
    ]

    sections |> List.flatten() |> Enum.join("\n")
  end

  defp format_result({:ok, data}, fun), do: fun.(data)
  defp format_result({:error, reason}, _fun), do: ["Error: #{inspect(reason)}"]
end
