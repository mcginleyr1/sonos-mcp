defmodule Sonosex.MCP.Tools.Group do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  alias Sonosex.Discovery
  alias Sonosex.UPnP.AVTransport

  @impl EMCP.Tool
  def name, do: "sonos_group"

  @impl EMCP.Tool
  def description, do: "Group Sonos speakers together. First speaker becomes the coordinator, rest join it."

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        speakers: %{
          type: :array,
          items: %{type: :string},
          description: "List of speaker names (2+). First becomes coordinator, rest join it.",
          minItems: 2
        }
      },
      required: [:speakers]
    }
  end

  @impl EMCP.Tool
  def call(_conn, params) do
    names = params["speakers"]

    with {:ok, speakers} <- resolve_all(names),
         [coordinator | members] = speakers,
         :ok <- join_all(members, coordinator) do
      member_names = Enum.map_join(members, ", ", & &1.name)
      ok_response("Grouped #{member_names} with coordinator #{coordinator.name}.")
    else
      {:error, reason} -> error_response(reason)
    end
  end

  defp resolve_all(names) do
    results = Enum.map(names, fn name ->
      case Discovery.find_by_name(name) do
        {:ok, speaker} -> {:ok, speaker}
        {:error, :not_found} -> {:error, "Speaker '#{name}' not found. Use sonos_discover to see available speakers."}
      end
    end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, _} = err -> err
      nil -> {:ok, Enum.map(results, fn {:ok, s} -> s end)}
    end
  end

  defp join_all(members, coordinator) do
    uri = "x-rincon:#{coordinator.uuid}"

    results = Enum.map(members, fn member ->
      case AVTransport.set_av_transport_uri(member.ip, uri) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, "Failed to join #{member.name}: #{inspect(reason)}"}
      end
    end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, _} = err -> err
      nil -> :ok
    end
  end
end
