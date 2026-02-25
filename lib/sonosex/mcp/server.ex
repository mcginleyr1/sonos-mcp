defmodule Sonosex.MCP.Server do
  use EMCP.Server,
    name: "sonosex",
    version: "0.2.0",
    tools: [
      Sonosex.MCP.Tools.Discover,
      Sonosex.MCP.Tools.Play,
      Sonosex.MCP.Tools.Pause,
      Sonosex.MCP.Tools.Stop,
      Sonosex.MCP.Tools.Next,
      Sonosex.MCP.Tools.Previous,
      Sonosex.MCP.Tools.NowPlaying,
      Sonosex.MCP.Tools.GetVolume,
      Sonosex.MCP.Tools.SetVolume,
      Sonosex.MCP.Tools.Mute,
      Sonosex.MCP.Tools.Seek,
      Sonosex.MCP.Tools.PlayMode,
      Sonosex.MCP.Tools.PlayUri,
      Sonosex.MCP.Tools.ClearQueue,
      Sonosex.MCP.Tools.Zones,
      Sonosex.MCP.Tools.SleepTimer
    ]
end
