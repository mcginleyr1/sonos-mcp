defmodule Sonosex.SOAP do
  require Record

  Record.defrecordp(:xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))
  Record.defrecordp(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  @services %{
    av_transport: {"/MediaRenderer/AVTransport/Control", "AVTransport:1"},
    rendering_control: {"/MediaRenderer/RenderingControl/Control", "RenderingControl:1"},
    group_rendering_control: {"/MediaRenderer/GroupRenderingControl/Control", "GroupRenderingControl:1"},
    device_properties: {"/DeviceProperties/Control", "DeviceProperties:1"},
    zone_group_topology: {"/ZoneGroupTopology/Control", "ZoneGroupTopology:1"},
    content_directory: {"/MediaServer/ContentDirectory/Control", "ContentDirectory:1"}
  }

  def call(ip, service, action, params \\ []) do
    {control_url, service_type} = Map.fetch!(@services, service)
    urn = "urn:schemas-upnp-org:service:#{service_type}"
    url = "http://#{ip}:1400#{control_url}"

    body = build_envelope(urn, action, params)

    case Req.post(url,
           body: body,
           headers: [
             {"content-type", ~s(text/xml; charset="utf-8")},
             {"soapaction", ~s("#{urn}##{action}")}
           ],
           receive_timeout: 5_000
         ) do
      {:ok, %{status: 200, body: response_body}} ->
        {:ok, parse_response(response_body, action)}

      {:ok, %{status: 500, body: error_body}} ->
        {:error, parse_error(error_body)}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def build_envelope(urn, action, params) do
    param_xml =
      params
      |> Enum.map(fn {key, value} ->
        ["<", to_string(key), ">", escape(to_string(value)), "</", to_string(key), ">"]
      end)

    [
      ~s(<?xml version="1.0" encoding="utf-8"?>),
      ~s(<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">),
      "<s:Body>",
      "<u:", to_string(action), ~s( xmlns:u="), urn, ~s(">),
      param_xml,
      "</u:", to_string(action), ">",
      "</s:Body>",
      "</s:Envelope>"
    ]
    |> IO.iodata_to_binary()
  end

  defp parse_response(body, action) do
    doc = body |> sanitize_xml() |> Sonosex.XML.parse()
    response_tag = String.to_atom("#{action}Response")

    case find_element(doc, response_tag) do
      nil -> %{}
      element -> Sonosex.XML.children_to_map(element)
    end
  end

  defp parse_error(body) do
    try do
      doc = Sonosex.XML.parse(body)

      error_code =
        case find_element(doc, :errorCode) do
          nil -> "unknown"
          el -> extract_text(el)
        end

      error_desc =
        case find_element(doc, :errorDescription) do
          nil -> "unknown error"
          el -> extract_text(el)
        end

      {:soap_error, error_code, error_desc}
    rescue
      _ -> {:parse_error, body}
    end
  end

  defp find_element(element, tag_name) when Record.is_record(element, :xmlElement) do
    if local_name_match?(xmlElement(element, :name), tag_name) do
      element
    else
      element
      |> xmlElement(:content)
      |> Enum.find_value(fn
        child when Record.is_record(child, :xmlElement) -> find_element(child, tag_name)
        _ -> nil
      end)
    end
  end

  defp find_element(_, _), do: nil

  defp local_name_match?(name, target) when name == target, do: true

  defp local_name_match?(name, target) do
    name_str = Atom.to_string(name)
    target_str = Atom.to_string(target)

    case String.split(name_str, ":", parts: 2) do
      [_prefix, local] -> local == target_str
      _ -> false
    end
  end

  defp extract_text(element) do
    element
    |> xmlElement(:content)
    |> Enum.filter(&Record.is_record(&1, :xmlText))
    |> Enum.map_join(fn text -> text |> xmlText(:value) |> to_string() end)
  end

  defp sanitize_xml(body) do
    String.replace(body, ~r/[^\x09\x0A\x0D\x20-\x7E]/, "")
  end

  defp escape(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
