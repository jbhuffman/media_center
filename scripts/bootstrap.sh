#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="srv/compose/arr"
APPDATA_BASE="/srv/appdata"
BACKUP_DIR="/srv/backups/arr"
MEDIA_GROUP="media"

echo "==> Creating appdata folders..."

APPDATA_DIRS=(
  gluetun
  qbittorrent
  radarr
  sonarr
  prowlarr
  overseerr
  bazarr
  recyclarr
  dozzle
  uptime-kuma
  homarr
)

for d in "${APPDATA_DIRS[@]}"; do
  sudo mkdir -p "${APPDATA_BASE}/${d}"
done

# Homarr subfolders
sudo mkdir -p "${APPDATA_BASE}/homarr/data" "${APPDATA_BASE}/homarr/configs" "${APPDATA_BASE}/homarr/icons"

echo "==> Creating backup folder..."
sudo mkdir -p "${BACKUP_DIR}"

echo "==> Ensuring /srv/compose/arr exists..."
sudo mkdir -p "/srv/compose/arr"
mkdir -p "${STACK_DIR}"

echo "==> Setting group ownership and setgid on /srv/appdata..."
sudo chgrp -R "${MEDIA_GROUP}" "${APPDATA_BASE}"
sudo chmod -R 2775 "${APPDATA_BASE}"

# Gluetun should remain root-owned
sudo chown -R root:root "${APPDATA_BASE}/gluetun"

echo "==> Ensuring .env exists..."
if [[ ! -f "${STACK_DIR}/.env" ]]; then
  if [[ -f "${STACK_DIR}/.env.example" ]]; then
    echo "==> Creating ${STACK_DIR}/.env from .env.example"
    cp "${STACK_DIR}/.env.example" "${STACK_DIR}/.env"
    echo "==> Edit ${STACK_DIR}/.env with real values before starting."
  else
    echo "==> No .env.example found at ${STACK_DIR}/.env.example"
    echo "==> Create ${STACK_DIR}/.env manually."
  fi
else
  echo "==> ${STACK_DIR}/.env already exists, leaving it alone."
fi

echo "==> Ensuring override exists..."
if [[ ! -f "${STACK_DIR}/docker-compose.override.yml" ]]; then
  if [[ -f "${STACK_DIR}/docker-compose.override.yml.example" ]]; then
    echo "==> Creating ${STACK_DIR}/docker-compose.override.yml from override example"
    cp "${STACK_DIR}/docker-compose.override.yml.example" "${STACK_DIR}/docker-compose.override.yml"
    echo "==> Review ${STACK_DIR}/docker-compose.override.yml and adjust paths for this host."
  else
    echo "==> No override example found at ${STACK_DIR}/docker-compose.override.yml.example"
    echo "==> Create ${STACK_DIR}/docker-compose.override.yml manually."
  fi
else
  echo "==> ${STACK_DIR}/docker-compose.override.yml already exists, leaving it alone."
fi

echo "==> Done."
echo "Next:"
echo "  1) make bootstrap"
echo "  2) cd /srv/compose/arr && docker compose config"
echo "  3) cd /srv/compose/arr && docker compose up -d"
