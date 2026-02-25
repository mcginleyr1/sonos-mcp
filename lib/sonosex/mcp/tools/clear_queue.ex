defmodule Sonosex.MCP.Tools.ClearQueue do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_clear_queue"

  @impl EMCP.Tool
  def description, do: "Clear the playback queue of a Sonos speaker"

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
      case Sonosex.UPnP.AVTransport.remove_all_tracks_from_queue(coordinator.ip) do
        {:ok, _} -> ok_response("Queue cleared on #{coordinator.name}.")
        {:error, reason} -> error_response("Failed to clear queue: #{inspect(reason)}")
      end
    end)
  end
end
