# Arr Stack on Raspberry Pi OS (PIA VPN + qBittorrent + Radarr + Sonarr + Prowlarr)
Docker Compose lives in srv/compose/arr.
Run all make commands from the repository root.

This repo runs:
- Gluetun (Private Internet Access VPN tunnel)
- qBittorrent (forced through the VPN tunnel)
- Radarr, Sonarr, Prowlarr (normal Docker network, clean LAN access)

## Prereqs
- Raspberry Pi OS with Docker + Docker Compose plugin installed
- A PIA account (OpenVPN creds)
- Optional but recommended: a dedicated disk mount for media

## Folder layout (recommended)
This matches the compose examples and keeps state out of your repo.

```bash
sudo mkdir -p /srv/compose/arr
sudo mkdir -p /srv/appdata/{gluetun,qbittorrent,radarr,sonarr,prowlarr}
sudo mkdir -p /srv/data/{torrents,movies,tv}
sudo chown -R 1000:1000 /srv/appdata /srv/data

# Cronjob to trigger nightly backup
crontab -e
0 3 * * * /path/to/repo/scripts/backup-appdata.sh >/tmp/arr_backup.log 2>&1


# Restore from backups
cd /srv/compose/arr
docker compose down
sudo tar -xzf /srv/backups/arr/appdata_YYYYMMDD_HHMMSS.tar.gz -C /srv/appdata
docker compose up -d
