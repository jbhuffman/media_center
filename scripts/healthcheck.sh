#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

say() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==>${NC} $*"; }
fail() { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

command -v docker >/dev/null 2>&1 || fail "docker not found"

say "Checking containers are running..."
docker ps --format 'table {{.Names}}\t{{.Status}}' | sed 1d || true

say "Checking Gluetun health endpoint..."
if docker exec gluetun sh -c 'wget -q --spider http://127.0.0.1:9999/'; then
  say "Gluetun health endpoint: OK"
else
  fail "Gluetun health endpoint failed. Check: docker logs gluetun"
fi

say "Checking public IP from inside VPN tunnel..."
VPN_IP="$(docker exec gluetun sh -c 'wget -qO- https://ipinfo.io/ip' 2>/dev/null | tr -d "\r\n" || true)"
if [[ -n "${VPN_IP}" ]]; then
  say "VPN egress IP: ${VPN_IP}"
else
  warn "Could not fetch VPN IP. Internet may be blocked or DNS not ready. Check gluetun logs."
fi

say "Checking port forwarding file (optional)..."
if docker exec gluetun sh -c 'test -f /gluetun/forwarded_port'; then
  PF_PORT="$(docker exec gluetun sh -c 'cat /gluetun/forwarded_port 2>/dev/null | tr -d "\r\n" | tr -cd "0-9"' || true)"
  if [[ -n "${PF_PORT}" ]]; then
    say "Forwarded port file present: ${PF_PORT}"
  else
    warn "forwarded_port file exists but is empty or non-numeric"
  fi
else
  warn "No /gluetun/forwarded_port found. If you enabled PIA port forwarding, check gluetun config/logs."
fi

say "Checking qBittorrent Web API responds..."
# qBittorrent shares gluetun network, so we test via gluetun container
if docker exec gluetun sh -c 'wget -q --spider http://127.0.0.1:8080/'; then
  say "qBittorrent Web UI reachable on gluetun:8080"
else
  fail "qBittorrent Web UI not reachable. Check: docker logs qbittorrent"
fi

say "Checking arr UIs respond..."
check_ui () {
  local name="$1"
  local url="$2"
  if docker exec "${name}" sh -c "wget -q --spider ${url}"; then
    say "${name} reachable: ${url}"
  else
    warn "${name} not reachable at ${url}. Container may still be starting."
  fi
}
check_ui radarr "http://127.0.0.1:7878/"
check_ui sonarr "http://127.0.0.1:8989/"
check_ui prowlarr "http://127.0.0.1:9696/"

say "All done. If everything is green, you are ready to hoard responsibly."
