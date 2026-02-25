#!/bin/sh
set -e

IMAGE="mcginleyr1/sonos-mcp:latest"
CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

echo "Discovering Sonos speakers on your network..."

SPEAKERS=$(python3 -c "
import socket, re

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.settimeout(3)

msg = '\r\n'.join([
    'M-SEARCH * HTTP/1.1',
    'HOST: 239.255.255.250:1900',
    'MAN: \"ssdp:discover\"',
    'MX: 3',
    'ST: urn:schemas-upnp-org:device:ZonePlayer:1',
    '', ''
]).encode()

sock.sendto(msg, ('239.255.255.250', 1900))

ips = set()
while True:
    try:
        data = sock.recv(4096).decode(errors='ignore')
        if 'ZonePlayer' in data or 'Sonos' in data:
            m = re.search(r'LOCATION:\s*http://([^:]+):1400', data, re.I)
            if m:
                ips.add(m.group(1))
    except socket.timeout:
        break

sock.close()
print(','.join(sorted(ips)))
")

if [ -z "$SPEAKERS" ]; then
    echo "No Sonos speakers found. Make sure you're on the same network."
    exit 1
fi

echo "Found speakers: $SPEAKERS"

echo ""
echo "Pulling Docker image..."
docker pull "$IMAGE"

echo ""
echo "Writing Claude Desktop config..."

if [ -f "$CONFIG" ]; then
    python3 -c "
import json, sys

with open(sys.argv[1]) as f:
    config = json.load(f)

config.setdefault('mcpServers', {})
config['mcpServers']['sonos-mcp'] = {
    'command': 'docker',
    'args': ['run', '--rm', '-i', '--network', 'host',
             '-e', 'SONOS_SPEAKERS=$SPEAKERS',
             '-e', 'ELIXIR_ERL_OPTIONS=+fnu',
             '$IMAGE'],
}

with open(sys.argv[1], 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
" "$CONFIG"
else
    mkdir -p "$(dirname "$CONFIG")"
    python3 -c "
import json

config = {
    'mcpServers': {
        'sonos-mcp': {
            'command': 'docker',
            'args': ['run', '--rm', '-i', '--network', 'host',
                     '-e', 'SONOS_SPEAKERS=$SPEAKERS',
                     '-e', 'ELIXIR_ERL_OPTIONS=+fnu',
                     '$IMAGE'],
        }
    }
}

with open('$CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
fi

echo ""
echo "Done! Restart Claude Desktop to connect to your Sonos speakers."
echo "Speakers configured: $SPEAKERS"
