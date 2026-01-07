#!/usr/bin/env bash
set -euo pipefail

ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*" ; }
die() { echo "❌ $*" ; exit 1; }

STACK_DIR="/srv/compose/arr"

cd "$STACK_DIR" || die "Cannot cd to $STACK_DIR"

ok "Docker compose ps"
docker compose ps

ok "Checking Gluetun health"
docker exec gluetun wget -q --spider http://127.0.0.1:9999/ || die "Gluetun health endpoint failed"

ok "Checking VPN egress IP (from Gluetun)"
VPN_IP="$(docker exec gluetun sh -c 'wget -qO- https://ipinfo.io/ip 2>/dev/null || true' | tr -d '\r\n')"
[[ -n "$VPN_IP" ]] && ok "VPN IP: $VPN_IP" || warn "Could not fetch VPN IP"

ok "Checking port-forward file exists (if enabled)"
if docker exec gluetun sh -c 'test -f /gluetun/forwarded_port'; then
  PF="$(docker exec gluetun sh -c 'cat /gluetun/forwarded_port | tr -cd "0-9"' || true)"
  [[ -n "$PF" ]] && ok "Forwarded port: $PF" || warn "forwarded_port exists but empty"
else
  warn "No /gluetun/forwarded_port found"
fi

ok "Checking qBittorrent Web UI reachable via gluetun namespace"
docker exec gluetun wget -q --spider http://127.0.0.1:8080/ || die "qBittorrent UI not reachable"

ok "Checking required mounts inside containers"
docker exec qbittorrent sh -c 'test -d /data/torrents' || die "qbittorrent missing /data/torrents"
docker exec sonarr sh -c 'test -d /data/torrents && test -d /usb1/tv' || die "sonarr missing mounts"
docker exec radarr sh -c 'test -d /data/torrents && test -d /usb1/movies' || die "radarr missing mounts"

ok "Write test: create+delete a temp file in downloads"
docker exec qbittorrent sh -c 'touch /data/torrents/.smoketest && rm -f /data/torrents/.smoketest' || die "Cannot write to /data/torrents"

ok "Smoke test passed"
