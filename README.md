# Sonosex

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
    "sonosex": {
      "command": "mix",
      "args": ["run", "--no-halt"],
      "cwd": "/path/to/sonosex"
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
    "sonosex": {
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

## How It Works

1. **Discovery**: SSDP multicast finds Sonos speakers on the LAN
2. **Topology**: Zone group state maps speakers to groups and coordinators
3. **Control**: SOAP calls to port 1400 on each speaker
4. **MCP**: Tools exposed over STDIO transport for AI assistant integration

Transport commands (play, pause, next, etc.) route to the group coordinator. Volume commands go directly to the target speaker.

## Architecture

```
lib/sonosex/
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
    tools/             # 16 MCP tool modules
```

## Running Standalone

```bash
mix run --no-halt
```

## Tests

```bash
mix test
```
