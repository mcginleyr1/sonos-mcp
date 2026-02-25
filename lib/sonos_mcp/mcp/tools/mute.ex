defmodule SonosMcp.MCP.Tools.Mute do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_mute"

  @impl EMCP.Tool
  def description, do: "Mute or unmute a Sonos speaker"

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        muted: %{type: :boolean, description: "true to mute, false to unmute"}
      },
      required: [:speaker_name, :muted]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    muted = params["muted"]

    with_speaker(params, fn speaker ->
      case SonosMcp.UPnP.RenderingControl.set_mute(speaker.ip, muted) do
        {:ok, _} ->
          action = if muted, do: "muted", else: "unmuted"
          ok_response("#{speaker.name} #{action}.")

        {:error, reason} ->
          error_response("Failed to set mute: #{inspect(reason)}")
      end
    end)
  end
end
