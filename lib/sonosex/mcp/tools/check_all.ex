defmodule Sonosex.MCP.Tools.CheckAll do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  alias Sonosex.{Discovery, Speaker}
  alias Sonosex.UPnP.AVTransport

  @impl EMCP.Tool
  def name, do: "sonos_check_all"

  @impl EMCP.Tool
  def description do
    "Quick health check across all discovered speakers. Shows transport state, group role, and connection status for each."
  end

  @impl EMCP.Tool
  def input_schema do
    %{type: :object, properties: %{}}
  end

  @impl EMCP.Tool
  def call(_conn, _params) do
    speakers = Discovery.list()

    case speakers do
      [] ->
        error_response("No speakers discovered. Run sonos_discover first.")

      speakers ->
        lines = Enum.map(speakers, &check_speaker/1)

        report = [
          "=== Speaker Health Check (#{length(speakers)} speakers) ===",
          "",
          Enum.join(lines, "\n\n")
        ] |> Enum.join("\n")

        ok_response(report)
    end
  end

  defp check_speaker(speaker) do
    role = if Speaker.coordinator?(speaker), do: "Coordinator", else: "Member"
    transport = AVTransport.get_transport_info(speaker.ip)

    {state, status} =
      case transport do
        {:ok, data} -> {data["CurrentTransportState"], data["CurrentTransportStatus"]}
        {:error, reason} -> {"ERROR", inspect(reason)}
      end

    flag = if status != "OK" and status != nil, do: " <<<", else: ""

    [
      "#{speaker.name} (#{speaker.model})",
      "  IP: #{speaker.ip} | Role: #{role} | Group: #{speaker.group_id}",
      "  Transport: #{state} | Status: #{status}#{flag}"
    ] |> Enum.join("\n")
  end
end
