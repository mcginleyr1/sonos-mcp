defmodule Sonosex.XML do
  require Record

  Record.defrecordp(:xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))
  Record.defrecordp(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))
  Record.defrecordp(:xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl"))

  def parse(xml_string) when is_binary(xml_string) do
    {doc, _rest} =
      xml_string
      |> String.to_charlist()
      |> :xmerl_scan.string(quiet: true)

    doc
  end

  def children_to_map(element) do
    element
    |> xmlElement(:content)
    |> Enum.reduce(%{}, fn
      child, acc when Record.is_record(child, :xmlElement) ->
        name = child |> xmlElement(:name) |> to_string()
        value = extract_text(xmlElement(child, :content))
        Map.put(acc, name, value)

      _other, acc ->
        acc
    end)
  end

  def get_attribute(element, attr_name) do
    element
    |> xmlElement(:attributes)
    |> Enum.find_value(fn attr ->
      if xmlAttribute(attr, :name) == attr_name do
        attr |> xmlAttribute(:value) |> to_string()
      end
    end)
  end

  def get_elements(element, tag_name) when is_atom(tag_name) do
    element
    |> xmlElement(:content)
    |> Enum.filter(fn
      child when Record.is_record(child, :xmlElement) ->
        xmlElement(child, :name) == tag_name

      _ ->
        false
    end)
  end

  def unescape_and_parse(encoded_xml) when is_binary(encoded_xml) do
    encoded_xml
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> parse()
  end

  defp extract_text(content) do
    content
    |> Enum.filter(&Record.is_record(&1, :xmlText))
    |> Enum.map_join(fn text -> text |> xmlText(:value) |> to_string() end)
  end
end
