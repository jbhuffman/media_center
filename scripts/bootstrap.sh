#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="srv/compose/arr"
APPDATA_BASE="/srv/appdata"
BACKUP_DIR="/srv/backups/arr"

echo "==> Creating folders..."
sudo mkdir -p "${APPDATA_BASE}"/{gluetun,qbittorrent,radarr,sonarr,prowlarr}
sudo mkdir -p "${BACKUP_DIR}"
sudo mkdir -p "/srv/compose/arr"

echo "==> Ensuring repo stack folder exists..."
mkdir -p "${STACK_DIR}"

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
echo "Next:"
echo "  1) Edit ${STACK_DIR}/.env"
echo "  2) Edit ${STACK_DIR}/docker-compose.override.yml (mount paths)"
echo "  3) Start: make up"
echo "  4) Verify: make smoke (or make health)"
