#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="srv/compose/arr"
APPDATA_BASE="/srv/appdata"
BACKUP_DIR="/srv/backups/arr"

# These should exist on the system already
MEDIA_GROUP="media"

echo "==> Creating appdata folders..."

sudo mkdir -p "${APPDATA_BASE}"/{
  gluetun,
  qbittorrent,
  radarr,
  sonarr,
  prowlarr,
  overseerr,
  bazarr,
  recyclarr,
  dozzle,
  uptime-kuma,
  homarr
}

# Homarr needs subfolders
sudo mkdir -p "${APPDATA_BASE}/homarr"/{data,configs,icons}

echo "==> Creating backup folder..."
sudo mkdir -p "${BACKUP_DIR}"

echo "==> Ensuring compose stack folder exists..."
sudo mkdir -p "/srv/compose/arr"
mkdir -p "${STACK_DIR}"

echo "==> Setting group ownership to ${MEDIA_GROUP} and permissions..."

# Apply group ownership and setgid so new files inherit group
sudo chgrp -R "${MEDIA_GROUP}" "${APPDATA_BASE}"
sudo chmod -R 2775 "${APPDATA_BASE}"

# Gluetun should remain root-owned (VPN + tun device)
sudo chown -R root:root "${APPDATA_BASE}/gluetun"

echo "==> Appdata layout created under ${APPDATA_BASE}:"
ls -1 "${APPDATA_BASE}"

# Copy .env from example if missing
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

# Copy override from example if missing
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
echo
echo "Next steps:"
echo "  1) Edit ${STACK_DIR}/.env (PUIDs, credentials, timezone)"
echo "  2) Edit ${STACK_DIR}/docker-compose.override.yml (downloads + USB mounts)"
echo "  3) Migrate existing app data into /srv/appdata/* as needed"
echo "  4) Start the stack: docker compose up -d"
echo "  5) Verify with: docker compose ps"
