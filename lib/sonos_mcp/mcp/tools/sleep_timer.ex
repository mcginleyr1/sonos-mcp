defmodule SonosMcp.MCP.Tools.SleepTimer do
  @behaviour EMCP.Tool

  import SonosMcp.MCP.Tools.Helpers

  @impl EMCP.Tool
  def name, do: "sonos_sleep_timer"

  @impl EMCP.Tool
  def description do
    "Set or cancel a sleep timer. Use HH:MM:SS format to set, or empty string to cancel."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speaker_name: %{type: :string, description: "Name of the Sonos speaker"},
        duration: %{type: :string, description: "Duration in HH:MM:SS format, or empty string to cancel"}
      },
      required: [:speaker_name, :duration]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    duration = params["duration"]

    with_coordinator(params, fn coordinator ->
      case SonosMcp.UPnP.AVTransport.configure_sleep_timer(coordinator.ip, duration) do
        {:ok, _} ->
          msg =
            if duration == "",
              do: "Sleep timer cancelled on #{coordinator.name}.",
              else: "Sleep timer set to #{duration} on #{coordinator.name}."

          ok_response(msg)

        {:error, reason} ->
          error_response("Failed to configure sleep timer: #{inspect(reason)}")
      end
    end)
  end
end
