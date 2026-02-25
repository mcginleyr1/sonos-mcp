defmodule Sonosex.MCP.Tools.Next do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_next"

  @impl EMCP.Tool
  def description, do: "Skip to the next track on a Sonos speaker or group"

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
      case Sonosex.UPnP.AVTransport.next(coordinator.ip) do
        {:ok, _} -> ok_response("Skipped to next track on #{coordinator.name}.")
        {:error, reason} -> error_response("Failed to skip: #{inspect(reason)}")
      end
    end)
  end
end
