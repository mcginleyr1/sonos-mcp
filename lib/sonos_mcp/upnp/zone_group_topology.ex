defmodule SonosMcp.UPnP.ZoneGroupTopology do
  alias SonosMcp.{SOAP, XML}

  def get_state(ip), do: SOAP.call(ip, :zone_group_topology, "GetZoneGroupState")

  def parse_zone_groups(zone_group_state_xml) do
    doc = XML.unescape_and_parse(zone_group_state_xml)

    doc
    |> XML.get_elements(:ZoneGroups)
    |> List.first()
    |> XML.get_elements(:ZoneGroup)
    |> Enum.map(&parse_zone_group/1)
  end

  defp parse_zone_group(group_element) do
    coordinator_uuid = XML.get_attribute(group_element, :Coordinator)
    group_id = XML.get_attribute(group_element, :ID)

    members =
      group_element
      |> XML.get_elements(:ZoneGroupMember)
      |> Enum.map(&parse_member/1)

    %{
      group_id: group_id,
      coordinator_uuid: coordinator_uuid,
      members: members
    }
  end

  defp parse_member(member_element) do
    uuid = XML.get_attribute(member_element, :UUID)
    name = XML.get_attribute(member_element, :ZoneName)
    location = XML.get_attribute(member_element, :Location)
    ip = extract_ip(location)

    %{uuid: uuid, name: name, ip: ip}
  end

  defp extract_ip(location) do
    uri = URI.parse(location)
    uri.host
  end
end
