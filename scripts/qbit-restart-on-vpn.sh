cat > srv/compose/arr/scripts/qbit-restart-on-vpn.sh <<'EOF'
#!/usr/bin/env sh
set -u

GLUETUN_CONTAINER="${GLUETUN_CONTAINER:-gluetun}"
QBIT_CONTAINER="${QBIT_CONTAINER:-qbittorrent}"
CHECK_INTERVAL="${CHECK_INTERVAL:-10}"

echo "Watching Gluetun health; will restart qBittorrent when VPN becomes healthy."
LAST_STATUS="unknown"

while true; do
  STATUS="$(docker inspect -f '{{.State.Health.Status}}' "$GLUETUN_CONTAINER" 2>/dev/null || echo unknown)"

  if [ "$STATUS" = "healthy" ] && [ "$LAST_STATUS" != "healthy" ]; then
    echo "$(date) Gluetun became healthy; restarting qBittorrent."
    docker restart "$QBIT_CONTAINER" >/dev/null 2>&1 || true
  fi

  LAST_STATUS="$STATUS"
  sleep "$CHECK_INTERVAL"
done
EOF

chmod +x srv/compose/arr/scripts/qbit-restart-on-vpn.sh
