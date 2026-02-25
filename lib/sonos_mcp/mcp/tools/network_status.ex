defmodule SonosMcp.MCP.Tools.NetworkStatus do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_network_status"

  @impl EMCP.Tool
  def description do
    "Get network diagnostics from a speaker including the network matrix (signal strength between speakers). Warning: may briefly interrupt playback on voice-enabled speakers."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker to query"}
      },
      required: [:speaker_name]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    with_speaker(params, fn speaker ->
      ip = speaker.ip

      review = fetch_text("http://#{ip}:1400/support/review")
      ifconfig = fetch_text("http://#{ip}:1400/status/ifconfig")

      report = [
        "=== Network Status via #{speaker.name} (#{ip}) ===",
        "",
        "-- Network Matrix (/support/review) --",
        format_review(review),
        "",
        "-- Interface Stats (/status/ifconfig) --",
        format_fetch(ifconfig)
      ] |> Enum.join("\n")

      ok_response(report)
    end)
  end

  defp fetch_text(url) do
    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_review({:ok, html}) do
    html
    |> String.replace(~r/<script[^>]*>.*?<\/script>/s, "")
    |> String.replace(~r/<style[^>]*>.*?<\/style>/s, "")
    |> String.replace(~r/<br\s*\/?>/, "\n")
    |> String.replace(~r/<\/tr>/, "\n")
    |> String.replace(~r/<\/td>/, " | ")
    |> String.replace(~r/<\/th>/, " | ")
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/&nbsp;/, " ")
    |> String.replace(~r/&amp;/, "&")
    |> String.replace(~r/&lt;/, "<")
    |> String.replace(~r/&gt;/, ">")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
  end

  defp format_review({:error, reason}), do: "Error fetching: #{inspect(reason)}"

  defp format_fetch({:ok, body}), do: String.trim(body)
  defp format_fetch({:error, reason}), do: "Error fetching: #{inspect(reason)}"
end
