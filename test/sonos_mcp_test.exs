defmodule SonosMcpTest do
  use ExUnit.Case

  describe "Speaker" do
    test "coordinator?/1 returns true when uuid matches coordinator_uuid" do
      speaker = %SonosMcp.Speaker{
        uuid: "RINCON_ABC",
        coordinator_uuid: "RINCON_ABC",
        ip: "192.168.1.10",
        name: "Living Room"
      }

      assert SonosMcp.Speaker.coordinator?(speaker)
    end

    test "coordinator?/1 returns false when uuid differs from coordinator_uuid" do
      speaker = %SonosMcp.Speaker{
        uuid: "RINCON_DEF",
        coordinator_uuid: "RINCON_ABC",
        ip: "192.168.1.11",
        name: "Kitchen"
      }

      refute SonosMcp.Speaker.coordinator?(speaker)
    end

    test "struct has all expected fields" do
      speaker = %SonosMcp.Speaker{}

      assert Map.has_key?(speaker, :ip)
      assert Map.has_key?(speaker, :name)
      assert Map.has_key?(speaker, :uuid)
      assert Map.has_key?(speaker, :model)
      assert Map.has_key?(speaker, :group_id)
      assert Map.has_key?(speaker, :coordinator_uuid)
      assert Map.has_key?(speaker, :household_id)
    end
  end

  describe "SOAP.build_envelope/3" do
    test "builds valid SOAP XML envelope" do
      urn = "urn:schemas-upnp-org:service:AVTransport:1"
      envelope = SonosMcp.SOAP.build_envelope(urn, "Play", InstanceID: 0, Speed: 1)

      assert envelope =~ ~s(<?xml version="1.0" encoding="utf-8"?>)
      assert envelope =~ ~s(<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/")
      assert envelope =~ ~s(<u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">)
      assert envelope =~ "<InstanceID>0</InstanceID>"
      assert envelope =~ "<Speed>1</Speed>"
      assert envelope =~ "</u:Play>"
    end

    test "builds envelope with no params" do
      urn = "urn:schemas-upnp-org:service:ZoneGroupTopology:1"
      envelope = SonosMcp.SOAP.build_envelope(urn, "GetZoneGroupState", [])

      assert envelope =~ ~s(<u:GetZoneGroupState xmlns:u="urn:schemas-upnp-org:service:ZoneGroupTopology:1">)
      assert envelope =~ "</u:GetZoneGroupState>"
    end

    test "escapes XML special characters in param values" do
      urn = "urn:schemas-upnp-org:service:AVTransport:1"
      envelope = SonosMcp.SOAP.build_envelope(urn, "SetAVTransportURI", CurrentURI: "http://example.com?a=1&b=2")

      assert envelope =~ "http://example.com?a=1&amp;b=2"
    end
  end

  describe "XML.parse/1" do
    test "parses simple XML" do
      doc = SonosMcp.XML.parse("<root><child>hello</child></root>")
      assert is_tuple(doc)
    end

    test "parses XML with attributes" do
      doc = SonosMcp.XML.parse(~s(<root attr="value"><child>text</child></root>))
      assert is_tuple(doc)
    end
  end

  describe "XML.children_to_map/1" do
    test "extracts child elements as string map" do
      doc = SonosMcp.XML.parse("<root><Name>Living Room</Name><Volume>42</Volume></root>")
      map = SonosMcp.XML.children_to_map(doc)

      assert map["Name"] == "Living Room"
      assert map["Volume"] == "42"
    end

    test "handles empty children" do
      doc = SonosMcp.XML.parse("<root></root>")
      map = SonosMcp.XML.children_to_map(doc)

      assert map == %{}
    end
  end

  describe "XML.get_attribute/2" do
    test "extracts attribute value" do
      doc = SonosMcp.XML.parse(~s(<zone UUID="RINCON_123" ZoneName="Kitchen"/>))
      assert SonosMcp.XML.get_attribute(doc, :UUID) == "RINCON_123"
      assert SonosMcp.XML.get_attribute(doc, :ZoneName) == "Kitchen"
    end

    test "returns nil for missing attribute" do
      doc = SonosMcp.XML.parse(~s(<zone UUID="RINCON_123"/>))
      assert SonosMcp.XML.get_attribute(doc, :Missing) == nil
    end
  end

  describe "XML.get_elements/2" do
    test "finds child elements by tag name" do
      doc = SonosMcp.XML.parse("<root><item>a</item><item>b</item><other>c</other></root>")
      items = SonosMcp.XML.get_elements(doc, :item)

      assert length(items) == 2
    end

    test "returns empty list when no matches" do
      doc = SonosMcp.XML.parse("<root><other>x</other></root>")
      assert SonosMcp.XML.get_elements(doc, :item) == []
    end
  end

  describe "XML.unescape_and_parse/1" do
    test "unescapes HTML entities and parses" do
      encoded = "&lt;root&gt;&lt;child&gt;hello&lt;/child&gt;&lt;/root&gt;"
      doc = SonosMcp.XML.unescape_and_parse(encoded)

      map = SonosMcp.XML.children_to_map(doc)
      assert map["child"] == "hello"
    end
  end
end
