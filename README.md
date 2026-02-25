# sonos-mcp

Local UPnP/SOAP MCP server for controlling Sonos speakers directly on your LAN. No cloud API, no OAuth, no registered domain needed.

Talks directly to speakers on port 1400 via UPnP/SOAP and exposes controls as MCP tools over STDIO.

## Requirements

- Elixir 1.19+
- Sonos speakers on the same network

## Setup

```bash
mix deps.get
mix compile
```

## Usage with Claude Desktop

### Via Mix (development)

Add to your Claude Desktop config (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "sonos-mcp": {
      "command": "mix",
      "args": ["run", "--no-halt"],
      "cwd": "/path/to/sonos-mcp"
    }
  }
}
```

### Via Docker

Build the image:

```bash
docker build -t mcginleyr1/sonos-mcp .
```

Add to your Claude Desktop config:

```json
{
  "mcpServers": {
    "sonos-mcp": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "--network", "host", "mcginleyr1/sonos-mcp"]
    }
  }
}
```

`-i` keeps stdin open for MCP STDIO transport. `--network host` is required for SSDP multicast discovery on your LAN.

**Note:** `--network host` only provides true host networking on **Linux**. On macOS, Docker runs inside a Linux VM (Docker Desktop, OrbStack, etc.) which blocks SSDP multicast from reaching your LAN. Use the Mix setup above for macOS development.

## Available MCP Tools

| Tool | Description |
|------|-------------|
| `sonos_discover` | Discover Sonos speakers on the local network |
| `sonos_play` | Start playback |
| `sonos_pause` | Pause playback |
| `sonos_stop` | Stop playback |
| `sonos_next` | Skip to next track |
| `sonos_previous` | Go to previous track |
| `sonos_now_playing` | Get current track info |
| `sonos_get_volume` | Get speaker volume (0-100) |
| `sonos_set_volume` | Set speaker volume (0-100) |
| `sonos_mute` | Mute/unmute a speaker |
| `sonos_seek` | Seek to position (HH:MM:SS) |
| `sonos_play_mode` | Set play mode (NORMAL, REPEAT_ALL, SHUFFLE, etc.) |
| `sonos_play_uri` | Play a URI (radio stream, audio file URL) |
| `sonos_clear_queue` | Clear the playback queue |
| `sonos_zones` | Get zone/group topology |
| `sonos_sleep_timer` | Set or cancel sleep timer |
| `sonos_group` | Group speakers together (first is coordinator) |
| `sonos_ungroup` | Remove a speaker from its group |
| `sonos_diagnostics` | Deep diagnostics for a speaker (transport, firmware, track info) |
| `sonos_network_status` | Network matrix and interface stats for troubleshooting |
| `sonos_check_all` | Quick health check across all discovered speakers |

## How It Works

1. **Discovery**: SSDP multicast finds Sonos speakers on the LAN
2. **Topology**: Zone group state maps speakers to groups and coordinators
3. **Control**: SOAP calls to port 1400 on each speaker
4. **MCP**: Tools exposed over STDIO transport for AI assistant integration

Transport commands (play, pause, next, etc.) route to the group coordinator. Volume commands go directly to the target speaker.

## Architecture

```
lib/sonos_mcp/
  speaker.ex           # Speaker struct
  xml.ex               # xmerl parsing helpers
  soap.ex              # SOAP envelope builder + HTTP caller
  discovery.ex         # SSDP GenServer for speaker discovery
  upnp/
    av_transport.ex    # Play, pause, seek, queue management
    rendering_control.ex # Volume, mute, bass, treble
    device_properties.ex # Zone info and attributes
    zone_group_topology.ex # Group/coordinator topology
    content_directory.ex # Queue browsing
  mcp/
    server.ex          # EMCP server with tool registration
    tools/             # 21 MCP tool modules
lib/mix/tasks/
  sonos.check.ex       # Fleet health check
  sonos.diag.ex        # Single speaker diagnostics
  sonos.network.ex     # Network matrix and interface stats
```

## CLI Diagnostics

Mix tasks for direct terminal use (no MCP protocol needed):

```bash
mix sonos.check              # fleet health check — all speakers, groups, firmware versions
mix sonos.diag "Office"      # deep diagnostics — transport, track, firmware, IP/MAC
mix sonos.network "Office"   # network matrix — WiFi signal, noise floor, packet drops
```

## Running Standalone

```bash
mix run --no-halt
```

## Tests

```bash
mix test
```
