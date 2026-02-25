defmodule SonosMcp.MCP.Tools.SetVolume do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_set_volume"

  @impl EMCP.Tool
  def description, do: "Set the volume level of a Sonos speaker (0-100)"

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        volume: %{type: :integer, description: "Volume level (0-100)"}
      },
      required: [:speaker_name, :volume]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    volume = params["volume"]

    cond do
      volume < 0 or volume > 100 ->
        error_response("Volume must be between 0 and 100.")

      true ->
        with_speaker(params, fn speaker ->
          case SonosMcp.UPnP.RenderingControl.set_volume(speaker.ip, volume) do
            {:ok, _} -> ok_response("Volume on #{speaker.name} set to #{volume}.")
            {:error, reason} -> error_response("Failed to set volume: #{inspect(reason)}")
          end
        end)
    end
  end
end
