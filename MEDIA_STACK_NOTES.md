# Media Stack Operations Notes

## What Depends on Gluetun

```
gluetun (VPN tunnel)
    │
    ├── qbittorrent (network_mode: service:gluetun)
    │   └── All torrent traffic forced through VPN
    │
    ├── qbit-port-sync (reads /gluetun/forwarded_port)
    │   └── Updates qBittorrent listening port when PIA assigns new port
    │
    ├── qbit_manage (connects to qBittorrent Web API)
    │   └── Scheduled tagging/housekeeping
    │
    └── qbit-restart-on-vpn (monitors gluetun health)
        └── Restarts qBittorrent when VPN reconnects
```

### Dependency Chain

| Service | Waits For | Condition |
|---------|-----------|-----------|
| qbittorrent | gluetun | `service_healthy` |
| qbit-port-sync | gluetun, qbittorrent | `service_healthy`, `service_started` |
| qbit_manage | gluetun, qbittorrent | `service_healthy`, `service_healthy` |
| recyclarr | sonarr, radarr | `service_healthy` |

### Independent Services (no dependencies)

These start immediately and don't care about VPN state:
- prowlarr
- radarr
- sonarr
- overseerr
- bazarr
- homarr
- dozzle
- uptime-kuma

---

## What Breaks First

### 1. Gluetun VPN Connection Fails

**Symptoms:**
- qBittorrent Web UI unreachable (port 8080)
- Gluetun logs show auth errors or connection timeouts
- `docker exec gluetun wget -qO- https://ipinfo.io/ip` returns nothing

**Cascade Effect:**
```
gluetun DOWN
    → qbittorrent has no network (cannot download/seed)
    → qbit-port-sync loops waiting for forwarded_port file
    → Radarr/Sonarr show "Download client unavailable"
```

**Check:**
```bash
docker logs gluetun --tail 50
docker inspect gluetun --format '{{.State.Health.Status}}'
```

### 2. PIA Port Forwarding Stops

**Symptoms:**
- `/gluetun/forwarded_port` is empty or missing
- qBittorrent shows "No incoming connections"
- Slow/stalled downloads

**Check:**
```bash
docker exec gluetun cat /gluetun/forwarded_port
docker logs qbit-port-sync --tail 20
```

### 3. qBittorrent Becomes Unreachable

**Symptoms:**
- Radarr/Sonarr show download client errors
- Web UI at :8080 times out

**Check:**
```bash
# Test from inside gluetun's network namespace
docker exec gluetun wget -q --spider http://127.0.0.1:8080/
docker logs qbittorrent --tail 50
```

### 4. Arr Services Can't Import

**Symptoms:**
- Downloads complete but don't move to library
- "Permission denied" in Radarr/Sonarr logs

**Check:**
```bash
# Verify mounts exist
docker exec sonarr ls -la /data/torrents
docker exec radarr ls -la /mnt/usb1/movies

# Check permissions
ls -la /home/qbittorrent-nox/Downloads
ls -la /mnt/usb1/movies
```

---

## Where Files Live

### Host Paths

| Path | Purpose |
|------|---------|
| `/srv/appdata/` | All container config/data |
| `/srv/appdata/gluetun/` | VPN config, forwarded_port file |
| `/srv/appdata/qbittorrent/` | qBit config, watched folders |
| `/srv/appdata/radarr/` | Radarr database, config |
| `/srv/appdata/sonarr/` | Sonarr database, config |
| `/srv/appdata/prowlarr/` | Indexer configs |
| `/srv/appdata/recyclarr/` | Quality profile cache |
| `/srv/appdata/qbit_manage/` | qbit_manage logs/runtime state |
| `/srv/appdata/recycle-bin/` | Sonarr/Radarr trash |
| `/srv/backups/arr/` | Backup archives |
| `/home/qbittorrent-nox/Downloads/` | Active torrent downloads |
| `/mnt/usb{1-4}/movies/` | Movie library storage |
| `/mnt/usb{1-4}/tv/` | TV library storage |

### Container Mount Mappings

| Container | Host Path | Container Path |
|-----------|-----------|----------------|
| qbittorrent | /home/qbittorrent-nox/Downloads | /data/torrents |
| sonarr | /home/qbittorrent-nox/Downloads | /data/torrents |
| sonarr | /mnt/usb{1-4}/tv | /mnt/usb{1-4}/tv |
| sonarr | /srv/appdata/recycle-bin/sonarr | /trash |
| radarr | /home/qbittorrent-nox/Downloads | /data/torrents |
| radarr | /mnt/usb{1-4}/movies | /mnt/usb{1-4}/movies |
| radarr | /srv/appdata/recycle-bin/radarr | /trash |
| bazarr | /mnt/usb{1-4}/tv | /mnt/usb{1-4}/tv |
| bazarr | /mnt/usb{1-4}/movies | /mnt/usb{1-4}/movies |

### Key Config Files

| File | Purpose |
|------|---------|
| `srv/compose/arr/.env` | Credentials, UIDs, API keys |
| `srv/compose/arr/docker-compose.yml` | Service definitions |
| `srv/compose/arr/docker-compose.override.yml` | Host-specific mounts |
| `/srv/appdata/gluetun/forwarded_port` | Current PIA port (updated by gluetun) |

---

## How to Recover

### VPN Won't Connect

```bash
# 1. Check credentials in .env
cat srv/compose/arr/.env | grep PIA

# 2. Try a different region
# Edit .env: PIA_REGION="CA Toronto"

# 3. Restart gluetun
cd /srv/compose/arr
docker compose restart gluetun

# 4. Watch logs
docker logs -f gluetun
```

### qBittorrent Stuck / Won't Start

```bash
# 1. Check if gluetun is healthy first
docker inspect gluetun --format '{{.State.Health.Status}}'

# 2. Restart qbittorrent
docker compose restart qbittorrent

# 3. If still broken, check for lock file
ls -la /srv/appdata/qbittorrent/qBittorrent/
# Remove any .lock files if present

# 4. Nuclear option - reset qbit config (preserves torrents)
docker compose down qbittorrent
sudo rm -rf /srv/appdata/qbittorrent/qBittorrent/config/*
docker compose up -d qbittorrent
```

### Downloads Not Importing (Permission Issues)

```bash
# 1. Check ownership
ls -la /home/qbittorrent-nox/Downloads/

# 2. Fix permissions
sudo chown -R 1000:1002 /home/qbittorrent-nox/Downloads
sudo chmod -R 2775 /home/qbittorrent-nox/Downloads

# 3. Verify media group ownership
sudo chgrp -R media /mnt/usb1/movies /mnt/usb1/tv
sudo chmod -R 2775 /mnt/usb1/movies /mnt/usb1/tv
```

### Full Stack Recovery (After Power Loss / Crash)

```bash
cd /srv/compose/arr

# 1. Check current state
docker compose ps

# 2. Bring everything down cleanly
docker compose down

# 3. Verify mounts are available
ls /mnt/usb1 /mnt/usb2 /mnt/usb3 /mnt/usb4
ls /home/qbittorrent-nox/Downloads

# 4. Start in order (compose handles this, but for clarity)
docker compose up -d

# 5. Verify health
./scripts/healthcheck.sh
```

### Restore from Backup

```bash
cd /srv/compose/arr

# 1. Stop everything
docker compose down

# 2. List available backups
ls -lt /srv/backups/arr/

# 3. Restore (pick your backup)
sudo tar -xzf /srv/backups/arr/appdata_YYYYMMDD_HHMMSS.tar.gz -C /srv/appdata

# 4. Start stack
docker compose up -d
```

### Recyclarr Sync Issues

```bash
# 1. Check API keys are correct
cat srv/compose/arr/.env | grep API_KEY

# 2. Test connectivity
docker exec recyclarr curl -s http://radarr:7878/api/v3/health -H "X-Api-Key: YOUR_KEY"
docker exec recyclarr curl -s http://sonarr:8989/api/v3/health -H "X-Api-Key: YOUR_KEY"

# 3. Force a sync
docker exec recyclarr recyclarr sync
```

---

## Quick Health Check Commands

```bash
# All containers running?
docker compose ps

# VPN working?
docker exec gluetun wget -qO- https://ipinfo.io/ip

# Port forwarding active?
docker exec gluetun cat /gluetun/forwarded_port

# qBittorrent reachable?
docker exec gluetun wget -q --spider http://127.0.0.1:8080/

# Full health check
make health

# Full smoke test
make smoke-test
```

---

## Service Ports Quick Reference

| Port | Service |
|------|---------|
| 3001 | Uptime Kuma |
| 5055 | Overseerr |
| 6767 | Bazarr |
| 7575 | Homarr |
| 7878 | Radarr |
| 8000 | Gluetun API |
| 8080 | qBittorrent |
| 8989 | Sonarr |
| 9696 | Prowlarr |
| 9999 | Dozzle |
