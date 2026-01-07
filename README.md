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
