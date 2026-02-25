defmodule Sonosex.MCP.Tools.Helpers do
  def with_speaker(params, fun) do
    name = params["speaker_name"]

    case Sonosex.Discovery.find_by_name(name) do
      {:ok, speaker} ->
        fun.(speaker)

      {:error, :not_found} ->
        error_response("Speaker '#{name}' not found. Use sonos_discover to see available speakers.")
    end
  end

  def with_coordinator(params, fun) do
    name = params["speaker_name"]

    case Sonosex.Discovery.resolve_coordinator(name) do
      {:ok, coordinator} ->
        fun.(coordinator)

      {:error, :not_found} ->
        error_response("Speaker '#{name}' not found. Use sonos_discover to see available speakers.")

      {:error, reason} ->
        error_response("Error resolving coordinator: #{inspect(reason)}")
    end
  end

  def format_result({:ok, data}) when is_map(data), do: Jason.encode!(data, pretty: true)
  def format_result({:ok, value}), do: to_string(value)
  def format_result({:error, reason}), do: "Error: #{inspect(reason)}"

  def ok_response(text), do: EMCP.Tool.response([%{"type" => "text", "text" => text}])
  def error_response(text), do: EMCP.Tool.error(text)
end
