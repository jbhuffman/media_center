# Maintenance Tasks

## Daily (Automated)

These run automatically via cron or container schedules:

| Task | Schedule | How |
|------|----------|-----|
| Recyclarr quality sync | 3:30 AM | Container cron (`CRON_SCHEDULE=30 3 * * *`) |
| qbit_manage run | Every 180 minutes (default) | Container schedule (`QBT_SCHEDULE`) |
| Appdata backup | 3:00 AM | Host cron (if configured) |

---

## Weekly Tasks

### Clear Recycle Bins

Sonarr and Radarr move deleted files to recycle bins instead of permanent deletion.

```bash
# Check recycle bin sizes
du -sh /srv/appdata/recycle-bin/*

# Clear them (files older than 7 days)
find /srv/appdata/recycle-bin/sonarr -type f -mtime +7 -delete
find /srv/appdata/recycle-bin/radarr -type f -mtime +7 -delete

# Or nuclear option - clear everything
sudo rm -rf /srv/appdata/recycle-bin/sonarr/*
sudo rm -rf /srv/appdata/recycle-bin/radarr/*
```

### Check Stalled Downloads

```bash
# List torrents via qBittorrent API
docker exec gluetun wget -qO- "http://127.0.0.1:8080/api/v2/torrents/info?filter=stalled" | jq '.[].name'
```

### Review Failed Imports

Check Radarr/Sonarr Activity → Queue for stuck items:
- Radarr: http://YOUR_IP:7878/activity/queue
- Sonarr: http://YOUR_IP:8989/activity/queue

---

## Monthly Tasks

### Update Container Images

```bash
cd /srv/compose/arr

# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --remove-orphans

# Or use make
make update
```

### Prune Docker System

```bash
# Remove unused images, networks, build cache
docker system prune -a

# Check disk usage
docker system df
```

### Verify Backups

```bash
# List recent backups
ls -lht /srv/backups/arr/ | head -10

# Check backup sizes (should be consistent)
du -h /srv/backups/arr/*.tar.gz | tail -10

# Test extraction (dry run)
tar -tzf /srv/backups/arr/appdata_LATEST.tar.gz | head -20
```

### Rotate Old Backups

Keep last 7-14 backups, delete older ones:

```bash
# List backups older than 14 days
find /srv/backups/arr -name "*.tar.gz" -mtime +14

# Delete them
find /srv/backups/arr -name "*.tar.gz" -mtime +14 -delete
```

### Check Disk Space

```bash
# Host filesystem
df -h /srv /home /mnt/usb*

# Inside containers
docker exec qbittorrent df -h /data/torrents
docker exec radarr df -h /mnt/usb1/movies
```

---

## Quarterly Tasks

### Review Indexer Health

In Prowlarr (http://YOUR_IP:9696):
- Check System → Status for indexer errors
- Remove dead indexers
- Test all active indexers

### Audit Quality Profiles

Review Recyclarr configs to ensure they still match your preferences:

```bash
cat srv/compose/arr/recyclarr/configs/radarr.yml
cat srv/compose/arr/recyclarr/configs/sonarr.yml
```

Force a manual sync after changes:

```bash
docker exec recyclarr recyclarr sync
```

### Check Log Sizes

Container logs can grow large:

```bash
# Find large log files
sudo find /var/lib/docker/containers -name "*.log" -size +100M

# Docker handles rotation, but check config
docker info | grep -i log
```

---

## Cron Setup

### Recommended Host Crontab

```bash
crontab -e
```

```cron
# Backup appdata at 3 AM daily
0 3 * * * /path/to/repo/scripts/backup-appdata.sh >> /tmp/arr_backup.log 2>&1

# Clear recycle bins weekly (Sunday 4 AM)
0 4 * * 0 find /srv/appdata/recycle-bin -type f -mtime +7 -delete

# Prune old backups monthly (1st of month, 5 AM)
0 5 1 * * find /srv/backups/arr -name "*.tar.gz" -mtime +14 -delete

# Health check every 6 hours (optional, for monitoring)
0 */6 * * * /path/to/repo/scripts/healthcheck.sh >> /tmp/arr_health.log 2>&1
```

---

## Maintenance Mode

When doing heavy maintenance, stop non-essential services:

```bash
cd /srv/compose/arr

# Stop arr services but keep VPN + qBit running
docker compose stop sonarr radarr prowlarr bazarr overseerr recyclarr

# Do your maintenance...

# Start them back up
docker compose start sonarr radarr prowlarr bazarr overseerr recyclarr
```

---

## Log Locations

| Service | How to View |
|---------|-------------|
| All containers | Dozzle at http://YOUR_IP:9999 |
| Specific container | `docker logs <container> --tail 100` |
| Gluetun VPN | `docker logs gluetun --tail 100` |
| qBittorrent | `docker logs qbittorrent --tail 100` |
| qbit_manage | `docker logs qbit_manage --tail 100` |
| Stack combined | `make logs` |

---

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias arr='cd /srv/compose/arr'
alias arrup='cd /srv/compose/arr && docker compose up -d'
alias arrdown='cd /srv/compose/arr && docker compose down'
alias arrlogs='cd /srv/compose/arr && docker compose logs -f --tail=100'
alias arrps='cd /srv/compose/arr && docker compose ps'
alias vpnip='docker exec gluetun wget -qO- https://ipinfo.io/ip'
```
