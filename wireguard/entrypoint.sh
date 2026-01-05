#!/usr/bin/env bash
set -euo pipefail

# Environment variables:
WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG="${WG_CONFIG:-/etc/wireguard/wg0.conf}"

echo "[entrypoint] WireGuard interface: ${WG_INTERFACE}"
echo "[entrypoint] WireGuard config: ${WG_CONFIG}"

if [[ ! -f "${WG_CONFIG}" ]]; then
  echo "[entrypoint] ERROR: WireGuard config not found at ${WG_CONFIG}"
  exit 1
fi

cleanup() {
  echo "[entrypoint] Caught termination signal, bringing down WireGuard interface..."
  if command -v wg-quick >/dev/null 2>&1; then
    if wg show "${WG_INTERFACE}" >/dev/null 2>&1; then
      wg-quick down "${WG_INTERFACE}" 2>&1 || echo "[entrypoint] WARNING: wg-quick down failed"
    else
      echo "[entrypoint] WireGuard interface ${WG_INTERFACE} is not up. Skipping wg-quick down."
    fi
  else
    echo "[entrypoint] WARNING: wg-quick not found, cannot bring interface down cleanly."
  fi
  echo "[entrypoint] Shutdown complete."
  exit 0
}

trap cleanup SIGTERM SIGINT

if ip link show "${WG_INTERFACE}" >/dev/null 2>&1; then
  echo "[entrypoint] WireGuard interface ${WG_INTERFACE} already exists, trying to bring it down first..."
  wg-quick down "${WG_INTERFACE}" 2>&1 || echo "[entrypoint] WARNING: wg-quick down failed (interface may be partially present)."
fi

echo "[entrypoint] Bringing up WireGuard interface..."
wg-quick up "${WG_INTERFACE}"

echo "[entrypoint] WireGuard is up."
echo "[entrypoint] Keeping container alive..."
tail -f /dev/null
