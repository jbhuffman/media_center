#!/usr/bin/env sh

GLUETUN_CONTAINER="${GLUETUN_CONTAINER:-gluetun}"
QBIT_CONTAINER="${QBIT_CONTAINER:-qbittorrent}"
CHECK_INTERVAL="${CHECK_INTERVAL:-10}"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

log "Starting VPN health watcher"
log "Gluetun container: $GLUETUN_CONTAINER"
log "qBittorrent container: $QBIT_CONTAINER"
log "Check interval: ${CHECK_INTERVAL}s"

LAST_STATUS="unknown"
ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  STATUS="$(docker inspect -f '{{.State.Health.Status}}' "$GLUETUN_CONTAINER" 2>&1)" || STATUS="error"

  # Log status every 60 iterations (~10 min at 10s interval) or on change
  if [ "$STATUS" != "$LAST_STATUS" ]; then
    log "Gluetun status changed: $LAST_STATUS -> $STATUS"
  elif [ $((ITERATION % 60)) -eq 0 ]; then
    log "Still running (iteration $ITERATION, gluetun: $STATUS)"
  fi

  if [ "$STATUS" = "healthy" ] && [ "$LAST_STATUS" != "healthy" ]; then
    log "Gluetun became healthy; restarting qBittorrent..."
    if docker restart "$QBIT_CONTAINER" >/dev/null 2>&1; then
      log "qBittorrent restarted successfully"
    else
      log "WARNING: Failed to restart qBittorrent"
    fi
  fi

  LAST_STATUS="$STATUS"
  sleep "$CHECK_INTERVAL"
done
