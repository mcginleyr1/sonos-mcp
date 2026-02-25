defmodule SonosMcp.MCP.Tools.PlayUri do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  alias SonosMcp.UPnP.AVTransport

  @impl EMCP.Tool
  def name, do: "sonos_play_uri"

  @impl EMCP.Tool
  def description, do: "Play a URI (radio stream, audio file URL, etc.) on a Sonos speaker"

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        uri: %{type: :string, description: "URI to play (radio stream URL, audio file URL, etc.)"}
      },
      required: [:speaker_name, :uri]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    uri = params["uri"]

    with_coordinator(params, fn coordinator ->
      ip = coordinator.ip

      with {:ok, _} <- AVTransport.set_av_transport_uri(ip, uri),
           {:ok, _} <- AVTransport.play(ip) do
        ok_response("Now playing #{uri} on #{coordinator.name}.")
      else
        {:error, reason} -> error_response("Failed to play URI: #{inspect(reason)}")
      end
    end)
  end
end
