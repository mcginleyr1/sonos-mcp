defmodule Sonosex.UPnP.DeviceProperties do
  alias Sonosex.SOAP

  def get_zone_info(ip), do: SOAP.call(ip, :device_properties, "GetZoneInfo")

  def get_zone_attributes(ip), do: SOAP.call(ip, :device_properties, "GetZoneAttributes")
end
