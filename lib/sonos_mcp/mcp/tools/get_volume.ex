defmodule SonosMcp.MCP.Tools.GetVolume do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_get_volume"

  @impl EMCP.Tool
  def description, do: "Get the volume level of a Sonos speaker"

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
      case SonosMcp.UPnP.RenderingControl.get_volume(speaker.ip) do
        {:ok, volume} -> ok_response("Volume on #{speaker.name}: #{volume}")
        {:error, reason} -> error_response("Failed to get volume: #{inspect(reason)}")
      end
    end)
  end
end
