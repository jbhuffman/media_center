#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="/srv/compose/arr"

ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
die() { echo "❌ $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

need_path_dir() {
  [[ -d "$1" ]] || die "Missing directory: $1"
}

need_path_file() {
  [[ -f "$1" ]] || die "Missing file: $1"
}

echo "==> Verifying bootstrap prerequisites..."

need_cmd docker
need_cmd awk
need_cmd sed
need_cmd grep

# Docker daemon reachable
docker info >/dev/null 2>&1 || die "Docker daemon not reachable (is Docker running? do you need sudo?)"
ok "Docker is running"

# Required stack files
need_path_dir "$STACK_DIR"
need_path_file "$STACK_DIR/docker-compose.yml"
need_path_file "$STACK_DIR/.env"
ok "Stack files exist"

# Required appdata dirs
APPDATA_DIRS=(
  "/srv/appdata/gluetun"
  "/srv/appdata/qbittorrent"
  "/srv/appdata/sonarr"
  "/srv/appdata/radarr"
  "/srv/appdata/prowlarr"
  "/srv/appdata/overseerr"
  "/srv/appdata/homarr"
  "/srv/appdata/homarr/data"
  "/srv/appdata/homarr/configs"
  "/srv/appdata/homarr/icons"
  "/srv/appdata/bazarr"
  "/srv/appdata/recyclarr"
  "/srv/appdata/dozzle"
  "/srv/appdata/uptime-kuma"
)

for d in "${APPDATA_DIRS[@]}"; do
  need_path_dir "$d"
done
ok "Appdata directories present"

# Validate media group exists
getent group media >/dev/null 2>&1 || die "Group 'media' does not exist"
ok "Group 'media' exists"

# Parse important vars from .env (minimal parsing, ignores comments)
env_get() {
  local key="$1"
  local val
  val="$(grep -E "^[[:space:]]*${key}=" "$STACK_DIR/.env" | tail -n 1 | sed -E "s/^[[:space:]]*${key}=//" | tr -d '\r')"
  echo "$val"
}

TZ_VAL="$(env_get TZ || true)"
[[ -n "$TZ_VAL" ]] || warn "TZ is not set in .env (compose hardcodes TZ in places, but setting in .env is nicer)"

# IDs you rely on
PGID_MEDIA="$(env_get PGID_MEDIA || true)"
[[ -n "$PGID_MEDIA" ]] || die "PGID_MEDIA is missing in $STACK_DIR/.env"

PUID_QBIT="$(env_get PUID_QBIT || true)"
PUID_SONARR="$(env_get PUID_SONARR || true)"
PUID_RADARR="$(env_get PUID_RADARR || true)"
PUID_PROWLARR="$(env_get PUID_PROWLARR || true)"
PUID_BAZARR="$(env_get PUID_BAZARR || true)"
PUID_TOOLS="$(env_get PUID_TOOLS || true)"

for v in PUID_QBIT PUID_SONARR PUID_RADARR PUID_PROWLARR PUID_BAZARR PUID_TOOLS; do
  val="$(env_get "$v" || true)"
  [[ -n "$val" ]] || die "$v is missing in $STACK_DIR/.env"
done
ok "Required PUID/PGID variables present"

# Verify host paths used by override exist if override is present
OVERRIDE="$STACK_DIR/docker-compose.override.yml"
if [[ -f "$OVERRIDE" ]]; then
  ok "Override file present"
  # Downloads path from your setup
  need_path_dir "/home/qbittorrent-nox/Downloads"

  # Media mount roots
  for i in 1 2 3 4; do
    need_path_dir "/mnt/usb${i}/tv"
    need_path_dir "/mnt/usb${i}/movies"
  done
  ok "Host download + media mount paths exist"
else
  warn "No docker-compose.override.yml found (ok if you truly don't need host-specific mounts)"
fi

# Check downloads permissions: group write + setgid recommended
DL="/home/qbittorrent-nox/Downloads"
if [[ -d "$DL" ]]; then
  perms="$(stat -c "%A %U %G" "$DL")"
  echo "==> Downloads perms: $perms"
  # Expect drwxrwsr-x or similar (setgid on dir)
  stat -c "%A" "$DL" | grep -q "s" || warn "Downloads dir does not have setgid bit (recommended): chmod 2775 $DL"
  # Group write should be set
  stat -c "%A" "$DL" | cut -c 6 | grep -q "w" || warn "Downloads dir is not group-writable (recommended): chmod g+w $DL"
fi

# Render compose config (catches syntax errors and missing env vars)
cd "$STACK_DIR"
docker compose config >/dev/null 2>&1 || die "docker compose config failed (syntax/env problem)"
ok "docker compose config renders cleanly"

echo
ok "Bootstrap verification passed"
echo "Next:"
echo "  cd $STACK_DIR && docker compose up -d"
