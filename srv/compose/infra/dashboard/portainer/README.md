# Portainer

Portainer Community Edition dashboard for managing the local Docker environment.

## First-time setup

```bash
mkdir -p /srv/appdata/infra/dashboard/portainer/data
cp .env.example .env
```

## Start

```bash
make infra-portainer-up
```

## Access

- URL: `https://YOUR_HOST:9443`

Portainer uses HTTPS on port `9443` by default and will present a self-signed certificate until you replace it.
