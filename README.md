# Arr Stack on Raspberry Pi OS (PIA VPN + qBittorrent + Radarr + Sonarr + Prowlarr)

Docker Compose lives in `srv/compose/arr`.
Run all make commands from the repository root.

## Services

| Service | Port | Description |
|---------|------|-------------|
| Gluetun | 8000 | PIA VPN tunnel (qBittorrent traffic flows through here) |
| qBittorrent | 8080 | Torrent client (via VPN) |
| Radarr | 7878 | Movie management |
| Sonarr | 8989 | TV series management |
| Prowlarr | 9696 | Indexer manager |
| Overseerr | 5055 | Media request portal |
| Bazarr | 6767 | Subtitle management |
| Homarr | 7575 | Dashboard |
| Recyclarr | - | Quality profile sync (runs on cron) |
| Dozzle | 9999 | Container log viewer |
| Uptime Kuma | 3001 | Service monitoring |

## Prerequisites

- Raspberry Pi OS with Docker + Docker Compose plugin installed
- A PIA account (OpenVPN creds)
- Optional but recommended: dedicated disk mounts for media (usb1-4)

## Quick Start

```bash
# 1. Clone the repo and run bootstrap
make bootstrap

# 2. Edit the .env file with your credentials
nano srv/compose/arr/.env

# 3. Edit the override file for your mount paths
nano srv/compose/arr/docker-compose.override.yml

# 4. Start the stack
make up
```

## Folder Layout

This matches the compose examples and keeps state out of your repo.

```bash
/srv/
  appdata/          # Container config/data
    gluetun/
    qbittorrent/
    radarr/
    sonarr/
    prowlarr/
    overseerr/
    bazarr/
    homarr/
    recyclarr/
    dozzle/
    uptime-kuma/
    recycle-bin/    # Trash for Sonarr/Radarr
  backups/arr/      # Backup archives
  compose/arr/      # Docker compose files

/home/qbittorrent-nox/Downloads/   # Active torrent downloads

/mnt/usb{1-4}/     # Media storage
  tv/
  movies/
```

## Make Commands

| Command | Description |
|---------|-------------|
| `make bootstrap` | Initial setup (creates directories, copies example files) |
| `make up` | Start all containers |
| `make down` | Stop all containers |
| `make restart` | Restart all containers |
| `make logs` | Tail container logs |
| `make ps` | Show running containers |
| `make update` | Pull latest images and restart |
| `make health` | Run health checks |
| `make smoke-test` | Run integration tests |
| `make backup` | Backup appdata (stops stack during backup) |

## Environment Variables

Key variables in `srv/compose/arr/.env`:

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone (e.g., America/New_York) |
| `PIA_USER` | PIA VPN username |
| `PIA_PASS` | PIA VPN password |
| `PIA_REGION` | VPN region (e.g., "CA Montreal") |
| `QBIT_USER` | qBittorrent Web UI username |
| `QBIT_PASS` | qBittorrent Web UI password |
| `PUID` | User ID for containers |
| `PGID` | Group ID for containers |
| `UMASK` | File creation mask |
| `HOST_DOWNLOADS` | Path to downloads directory on host |
| `RADARR_API_KEY` | Radarr API key (for Recyclarr) |
| `SONARR_API_KEY` | Sonarr API key (for Recyclarr) |

## Backup & Restore

### Automated Backup (cron)

```bash
crontab -e
# Add this line for nightly backup at 3 AM:
0 3 * * * /path/to/repo/scripts/backup-appdata.sh >/tmp/arr_backup.log 2>&1
```

### Manual Restore

```bash
cd /srv/compose/arr
docker compose down
sudo tar -xzf /srv/backups/arr/appdata_YYYYMMDD_HHMMSS.tar.gz -C /srv/appdata
docker compose up -d
```

## VPN Architecture

- **Gluetun** establishes the PIA VPN tunnel
- **qBittorrent** uses `network_mode: "service:gluetun"` to route all traffic through VPN
- **qbit-port-sync** monitors PIA's forwarded port and updates qBittorrent automatically
- All other services run on the normal Docker bridge network with LAN access

## License

MIT License - See LICENSE.md
