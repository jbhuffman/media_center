# Bitmagnet

Docker Compose project for Bitmagnet and its Postgres database.

## First-time setup

```bash
mkdir -p /srv/appdata/infra/search/bitmagnet/config
mkdir -p /srv/appdata/infra/search/bitmagnet/postgres

cp .env.example .env
```

Bring the media stack up at least once before starting Bitmagnet so the external `arr_arrnet` Docker network exists.

## Start

```bash
make infra-bitmagnet-up
```

## URLs

- Web UI: `http://YOUR_HOST:3333/webui`
- Health: `http://YOUR_HOST:3333/status`
- Torznab endpoint for Prowlarr: `http://infra_search_bitmagnet:3333/torznab`

If Prowlarr is on the `arr_arrnet` Docker network, you can also use `http://bitmagnet:3333/torznab`.
