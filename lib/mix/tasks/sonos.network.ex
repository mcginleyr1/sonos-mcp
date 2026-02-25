defmodule Mix.Tasks.Sonos.Network do
  use Mix.Task

  alias SonosMcp.Discovery

  @shortdoc "Network diagnostics: WiFi matrix and interface stats from a Sonos speaker"

  def run(args) do
    case args do
      [] ->
        Mix.shell().error("Usage: mix sonos.network <speaker_name>")

      [name | _] ->
        Mix.Tasks.Sonos.ensure_discovery()

        case Discovery.find_by_name(name) do
          {:ok, speaker} -> print_network(speaker)
          {:error, :not_found} -> Mix.shell().error("Speaker '#{name}' not found.")
        end
    end
  end

  defp print_network(speaker) do
    ip = speaker.ip
    io = Mix.shell()

    io.info("=== Network Status: #{speaker.name} (#{ip}) ===\n")

    io.info("-- Network Matrix (/support/review) --")
    case fetch("http://#{ip}:1400/support/review") do
      {:ok, html} -> io.info(strip_html(html))
      {:error, reason} -> io.error("Error: #{inspect(reason)}")
    end

    io.info("\n-- Interface Stats (/status/ifconfig) --")
    case fetch("http://#{ip}:1400/status/ifconfig") do
      {:ok, body} -> io.info(String.trim(body))
      {:error, reason} -> io.error("Error: #{inspect(reason)}")
    end
  end

  defp fetch(url) do
    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp strip_html(html) do
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
end
