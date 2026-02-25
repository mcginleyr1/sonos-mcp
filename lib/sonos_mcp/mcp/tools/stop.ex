defmodule SonosMcp.MCP.Tools.Stop do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_stop"

  @impl EMCP.Tool
  def description, do: "Stop playback on a Sonos speaker or group"

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
      case SonosMcp.UPnP.AVTransport.stop(coordinator.ip) do
        {:ok, _} -> ok_response("Playback stopped on #{coordinator.name}.")
        {:error, reason} -> error_response("Failed to stop: #{inspect(reason)}")
      end
    end)
  end
end
