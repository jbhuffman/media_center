#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="/srv/compose/arr"
APPDATA_DIR="/srv/appdata"
BACKUP_DIR="/srv/backups/arr"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="${BACKUP_DIR}/appdata_${TS}.tar.gz"

sudo mkdir -p "$BACKUP_DIR"

echo "Stopping stack..."
cd "$STACK_DIR"
docker compose down

echo "Creating backup: $OUT"
sudo tar -czf "$OUT" -C "$APPDATA_DIR" .

echo "Starting stack..."
docker compose up -d

echo "Backup complete."
echo "$OUT"
