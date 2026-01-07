#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="srv/compose/arr"
APPDATA_BASE="/srv/appdata"
DATA_BASE="/srv/data"

# Default to the current user, but allow overrides:
PUID="${PUID:-$(id -u)}"
PGID="${PGID:-$(id -g)}"

echo "==> Using PUID=${PUID} PGID=${PGID}"
echo "==> Creating folders..."

sudo mkdir -p "${APPDATA_BASE}"/{gluetun,qbittorrent,radarr,sonarr,prowlarr}
sudo mkdir -p "${DATA_BASE}"/{torrents,movies,tv}
sudo mkdir -p "/srv/compose/arr"

echo "==> Setting ownership on /srv/appdata and /srv/data..."
sudo chown -R "${PUID}:${PGID}" "${APPDATA_BASE}" "${DATA_BASE}"

echo "==> Ensuring stack folder exists..."
mkdir -p "${STACK_DIR}"

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

echo "==> Done."
echo "Next:"
echo "  1) Edit ${STACK_DIR}/.env"
echo "  2) Start: make up"
echo "  3) Verify: make health"
