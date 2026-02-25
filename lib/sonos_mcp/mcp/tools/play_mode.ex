defmodule SonosMcp.MCP.Tools.PlayMode do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @valid_modes ~w(NORMAL REPEAT_ALL REPEAT_ONE SHUFFLE_NOREPEAT SHUFFLE SHUFFLE_REPEAT_ONE)

  @impl EMCP.Tool
  def name, do: "sonos_play_mode"

  @impl EMCP.Tool
  def description do
    "Set play mode (NORMAL, REPEAT_ALL, REPEAT_ONE, SHUFFLE_NOREPEAT, SHUFFLE, SHUFFLE_REPEAT_ONE)"
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        mode: %{type: :string, description: "Play mode: NORMAL, REPEAT_ALL, REPEAT_ONE, SHUFFLE_NOREPEAT, SHUFFLE, SHUFFLE_REPEAT_ONE"}
      },
      required: [:speaker_name, :mode]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    mode = params["mode"]

    if mode in @valid_modes do
      with_coordinator(params, fn coordinator ->
        case SonosMcp.UPnP.AVTransport.set_play_mode(coordinator.ip, mode) do
          {:ok, _} -> ok_response("Play mode set to #{mode} on #{coordinator.name}.")
          {:error, reason} -> error_response("Failed to set play mode: #{inspect(reason)}")
        end
      end)
    else
      error_response("Invalid play mode '#{mode}'. Valid modes: #{Enum.join(@valid_modes, ", ")}")
    end
  end
end
