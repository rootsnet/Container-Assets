#!/bin/bash
set -e

# Which Kea service this container runs: 4 (DHCPv4) or 6 (DHCPv6). Default: 6.
# One image, two daemons -> run one per container, selected via KEA_SERVICE.
KEA_SERVICE="${KEA_SERVICE:-6}"
CONFIG_FILE="/etc/kea/kea-dhcp${KEA_SERVICE}.conf"
BIN="kea-dhcp${KEA_SERVICE}"

# Ensure runtime dirs exist
mkdir -p /run/kea /var/lib/kea

# Sanity check config presence
if [ ! -f "$CONFIG_FILE" ]; then
  echo "ERROR: Kea config not found at $CONFIG_FILE" >&2
  exit 1
fi

# Execute the selected Kea daemon in foreground
exec "$BIN" -c "$CONFIG_FILE"
