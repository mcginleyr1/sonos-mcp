defmodule SonosMcp.MCP.Tools.NowPlaying do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  alias SonosMcp.UPnP.AVTransport

  @impl EMCP.Tool
  def name, do: "sonos_now_playing"

  @impl EMCP.Tool
  def description, do: "Get information about what is currently playing on a Sonos speaker"

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
    with_coordinator(params, fn coordinator ->
      ip = coordinator.ip

      with {:ok, position} <- AVTransport.get_position_info(ip),
           {:ok, transport} <- AVTransport.get_transport_info(ip) do
        text = format_now_playing(coordinator.name, position, transport)
        ok_response(text)
      else
        {:error, reason} -> error_response("Failed to get playback info: #{inspect(reason)}")
      end
    end)
  end

  defp format_now_playing(speaker_name, position, transport) do
    state = transport["CurrentTransportState"] || "UNKNOWN"
    track = position["TrackURI"] || ""
    title = extract_metadata(position, "dc:title")
    artist = extract_metadata(position, "dc:creator")
    album = extract_metadata(position, "upnp:album")
    track_num = position["Track"] || "?"
    duration = position["TrackDuration"] || "00:00:00"
    rel_time = position["RelTime"] || "00:00:00"

    lines = ["Now playing on #{speaker_name}:", "State: #{state}"]

    lines =
      lines ++
        if(title != "", do: ["Title: #{title}"], else: []) ++
        if(artist != "", do: ["Artist: #{artist}"], else: []) ++
        if(album != "", do: ["Album: #{album}"], else: []) ++
        [
          "Track: #{track_num}",
          "Position: #{rel_time} / #{duration}",
          "URI: #{track}"
        ]

    Enum.join(lines, "\n")
  end

  defp extract_metadata(position, tag) do
    case position["TrackMetaData"] do
      nil -> ""
      "" -> ""
      metadata -> extract_tag_value(metadata, tag)
    end
  end

  defp extract_tag_value(xml_string, tag) do
    regex = ~r/<#{Regex.escape(tag)}>(.*?)<\/#{Regex.escape(tag)}>/s

    case Regex.run(regex, xml_string) do
      [_, value] -> xml_unescape(value)
      _ -> ""
    end
  rescue
    _ -> ""
  end

  defp xml_unescape(text) do
    text
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
  end
end
