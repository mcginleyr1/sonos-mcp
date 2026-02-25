defmodule Sonosex.MCP.Tools.Zones do
  @behaviour EMCP.Tool

  import Sonosex.MCP.Tools.Helpers

  alias Sonosex.UPnP.ZoneGroupTopology

  @impl EMCP.Tool
  def name, do: "sonos_zones"

  @impl EMCP.Tool
  def description, do: "Get the current zone/group topology of the Sonos system"

  @impl EMCP.Tool
  def input_schema do
    %{type: :object, properties: %{}, required: []}
  end

  @impl EMCP.Tool
  def call(_conn, _args) do
    speakers = Sonosex.Discovery.list()

    case speakers do
      [] ->
        error_response("No speakers found. Run sonos_discover first.")

      [first | _] ->
        case ZoneGroupTopology.get_state(first.ip) do
          {:ok, %{"ZoneGroupState" => state_xml}} ->
            groups = ZoneGroupTopology.parse_zone_groups(state_xml)
            ok_response(format_zones(groups))

          {:ok, _} ->
            error_response("Unexpected response from zone group topology.")

          {:error, reason} ->
            error_response("Failed to get zone topology: #{inspect(reason)}")
        end
    end
  end

  defp format_zones(groups) do
    groups
    |> Enum.with_index(1)
    |> Enum.map_join("\n\n", fn {group, idx} ->
      coordinator = group.coordinator_uuid
      members = Enum.map_join(group.members, "\n", fn m ->
        coord_marker = if m.uuid == coordinator, do: " [coordinator]", else: ""
        "  - #{m.name} (#{m.ip})#{coord_marker}"
      end)
      "Group #{idx} (#{group.group_id}):\n#{members}"
    end)
  end
end
