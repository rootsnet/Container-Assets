#!/usr/bin/env bash
set -euo pipefail

NFT_RULES="${NFT_RULES:-/opt/nft/nft-rules.nft}"
GEOIP_RULES="${GEOIP_RULES:-/opt/nft/allowed-cidr.nft}"
NFT_APPLY_INTERVAL="${NFT_APPLY_INTERVAL:-10}"
NFT_MODE="${NFT_MODE:-watch}"  # init | watch

log() { echo "[$(date -Is)] [nft-sidecar] $*"; }

hash_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    sha256sum "$f" | awk '{print $1}'
  else
    echo "MISSING"
  fi
}

apply_rules() {
  if [[ ! -f "$NFT_RULES" ]]; then
    log "rules file not found: $NFT_RULES"
    return 1
  fi

  # Optional: if your nft-rules.nft includes GEOIP_RULES, then GEOIP_RULES should exist
  # We don't fail hard here to keep it flexible for early tests.
  if [[ ! -f "$GEOIP_RULES" ]]; then
    log "WARNING: geoip file not found: $GEOIP_RULES (nft include may fail if referenced)"
  fi

  if ! nft -c -f "$NFT_RULES" >/dev/null 2>&1; then
    log "nft syntax check failed for: $NFT_RULES"
    nft -c -f "$NFT_RULES" || true
    return 1
  fi

  log "applying rules: $NFT_RULES"
  nft -f "$NFT_RULES"
  log "applied OK"
}

log "starting (mode=${NFT_MODE}, NFT_RULES=${NFT_RULES}, GEOIP_RULES=${GEOIP_RULES}, interval=${NFT_APPLY_INTERVAL}s)"

if [[ "${NFT_MODE}" == "init" ]]; then
  apply_rules
  log "init mode complete; exiting"
  exit 0
fi

last_combo=""

while true; do
  # combine hashes so that a change in either file triggers apply
  h1="$(hash_file "$NFT_RULES")"
  h2="$(hash_file "$GEOIP_RULES")"
  combo="${h1}:${h2}"

  if [[ "$combo" != "$last_combo" ]]; then
    log "detected change (or first load). combo=${combo}"
    if apply_rules; then
      last_combo="$combo"
    else
      log "apply failed; will retry"
    fi
  fi

  sleep "$NFT_APPLY_INTERVAL"
done
