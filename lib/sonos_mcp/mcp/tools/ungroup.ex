defmodule SonosMcp.MCP.Tools.Ungroup do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  alias SonosMcp.UPnP.AVTransport

  @impl EMCP.Tool
  def name, do: "sonos_ungroup"

  @impl EMCP.Tool
  def description, do: "Remove a Sonos speaker from its group, making it standalone."

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker to ungroup"}
      },
      required: [:speaker_name]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    with_speaker(params, fn speaker ->
      case AVTransport.become_standalone(speaker.ip) do
        {:ok, _} -> ok_response("#{speaker.name} is now standalone.")
        {:error, reason} -> error_response("Failed to ungroup #{speaker.name}: #{inspect(reason)}")
      end
    end)
  end
end
