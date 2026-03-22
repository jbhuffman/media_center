# Bitmagnet

Docker Compose project for Bitmagnet and its Postgres database.

## First-time setup

```bash
mkdir -p /srv/appdata/infra/search/bitmagnet/config
mkdir -p /srv/appdata/infra/search/bitmagnet/postgres

cp .env.example .env
```

Bring the media stack up at least once before starting Bitmagnet so the external `arr_arrnet` Docker network exists.
Keep the media stack running when Bitmagnet is running, because Bitmagnet shares the `gluetun` container's network namespace for VPN egress.
Bitmagnet also waits for Gluetun's health endpoint before starting its worker process, so it will stay in a retry loop until the VPN is actually up.

## Start

```bash
make up
make infra-bitmagnet-up
```

## URLs

- Web UI: `http://YOUR_HOST:3333/webui`
- Health: `http://YOUR_HOST:3333/status`
- Torznab endpoint for Prowlarr: `http://gluetun:3333/torznab`

If Prowlarr is on the `arr_arrnet` Docker network, use `http://gluetun:3333/torznab` because Bitmagnet shares Gluetun's network namespace.
