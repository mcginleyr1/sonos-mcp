defmodule SonosMcp.MCP.Tools.Discover do
  @behaviour EMCP.Tool

  @impl EMCP.Tool
  def name, do: "sonos_discover"

  @impl EMCP.Tool
  def description, do: "Discover Sonos speakers on the local network"

  @impl EMCP.Tool
  def input_schema do
    %{type: :object, properties: %{}, required: []}
  end

  @impl EMCP.Tool
  def call(_conn, _args) do
    SonosMcp.Discovery.refresh()
    speakers = SonosMcp.Discovery.list()

    case speakers do
      [] ->
        EMCP.Tool.response([%{"type" => "text", "text" => "No Sonos speakers found on the network."}])

      speakers ->
        text =
          speakers
          |> Enum.map_join("\n", fn speaker ->
            coordinator = if SonosMcp.Speaker.coordinator?(speaker), do: " [coordinator]", else: ""
            "- #{speaker.name} (#{speaker.ip}) model=#{speaker.model}#{coordinator}"
          end)

        EMCP.Tool.response([%{"type" => "text", "text" => "Found #{length(speakers)} speaker(s):\n#{text}"}])
    end
  end
end
