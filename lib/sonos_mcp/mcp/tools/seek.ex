defmodule SonosMcp.MCP.Tools.Seek do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_seek"

  @impl EMCP.Tool
  def description, do: "Seek to a position in the current track (HH:MM:SS format)"

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        position: %{type: :string, description: "Position in HH:MM:SS format"}
      },
      required: [:speaker_name, :position]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    position = params["position"]

    with_coordinator(params, fn coordinator ->
      case SonosMcp.UPnP.AVTransport.seek(coordinator.ip, position) do
        {:ok, _} -> ok_response("Seeked to #{position} on #{coordinator.name}.")
        {:error, reason} -> error_response("Failed to seek: #{inspect(reason)}")
      end
    end)
  end
end
