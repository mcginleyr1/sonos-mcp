defmodule SonosMcp.MCP.Tools.Play do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_play"

  @impl EMCP.Tool
  def description, do: "Start playback on a Sonos speaker or group"

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
      case SonosMcp.UPnP.AVTransport.play(coordinator.ip) do
        {:ok, _} -> ok_response("Playback started on #{coordinator.name}.")
        {:error, reason} -> error_response("Failed to play: #{inspect(reason)}")
      end
    end)
  end
end
