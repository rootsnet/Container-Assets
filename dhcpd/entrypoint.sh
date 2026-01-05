#!/bin/bash
set -e

CONFIG_FILE="/etc/dhcp/dhcpd.conf"
LEASE_FILE="/var/lib/dhcp/dhcpd.leases"
PID_FILE="/run/dhcp-server/dhcpd.pid"

# If custom config file exists, use it
if [ -f /etc/ltsp/dhcpd.conf ]; then
  CONFIG_FILE="/etc/ltsp/dhcpd.conf"
fi

# Ensure lease file exists
[ -e "$LEASE_FILE" ] || touch "$LEASE_FILE"

# Set ownership and permissions
chown root:dhcpd /var/lib/dhcp "$LEASE_FILE"
chmod 775 /var/lib/dhcp
chmod 664 "$LEASE_FILE"

# Execute DHCP server in IPv4 mode
exec dhcpd -user dhcpd -group dhcpd -f -d -4 -pf "$PID_FILE" -cf "$CONFIG_FILE" $INTERFACESv4
