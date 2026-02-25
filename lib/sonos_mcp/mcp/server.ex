defmodule SonosMcp.MCP.Server do
  use EMCP.Server,
    name: "sonos-mcp",
    version: "0.2.0",
    tools: [
      SonosMcp.MCP.Tools.Discover,
      SonosMcp.MCP.Tools.Play,
      SonosMcp.MCP.Tools.Pause,
      SonosMcp.MCP.Tools.Stop,
      SonosMcp.MCP.Tools.Next,
      SonosMcp.MCP.Tools.Previous,
      SonosMcp.MCP.Tools.NowPlaying,
      SonosMcp.MCP.Tools.GetVolume,
      SonosMcp.MCP.Tools.SetVolume,
      SonosMcp.MCP.Tools.Mute,
      SonosMcp.MCP.Tools.Seek,
      SonosMcp.MCP.Tools.PlayMode,
      SonosMcp.MCP.Tools.PlayUri,
      SonosMcp.MCP.Tools.ClearQueue,
      SonosMcp.MCP.Tools.Zones,
      SonosMcp.MCP.Tools.SleepTimer,
      SonosMcp.MCP.Tools.Group,
      SonosMcp.MCP.Tools.Ungroup,
      SonosMcp.MCP.Tools.Diagnostics,
      SonosMcp.MCP.Tools.NetworkStatus,
      SonosMcp.MCP.Tools.CheckAll
    ]
end
