# Indexer Setup (Prowlarr)

## Overview

Prowlarr manages all torrent indexers in one place and syncs them to Radarr/Sonarr automatically.

**Web UI:** http://YOUR_IP:9696

---

## How It Works

```
Prowlarr (indexer manager)
    │
    ├── Syncs indexers to → Radarr
    ├── Syncs indexers to → Sonarr
    └── Syncs indexers to → (other apps if added)
```

When you add an indexer to Prowlarr, it automatically appears in Radarr and Sonarr. No need to configure indexers in each app separately.

---

## Initial Setup

### 1. Connect Prowlarr to Radarr/Sonarr

In Prowlarr: **Settings → Apps**

**Add Radarr:**
- Prowlarr Server: `http://prowlarr:9696`
- Radarr Server: `http://radarr:7878`
- API Key: (get from Radarr → Settings → General)

**Add Sonarr:**
- Prowlarr Server: `http://prowlarr:9696`
- Sonarr Server: `http://sonarr:8989`
- API Key: (get from Sonarr → Settings → General)

### 2. Add Indexers

In Prowlarr: **Indexers → Add Indexer**

Search for your indexer and configure credentials.

---

## Recommended Public Indexers

These don't require accounts:

| Indexer | Type | Notes |
|---------|------|-------|
| 1337x | Public | Large general tracker |
| EZTV | Public | TV focused |
| LimeTorrents | Public | General |
| RARBG (mirrors) | Public | High quality releases (original is dead, mirrors exist) |
| TorrentGalaxy | Public | General, good for new releases |
| YTS | Public | Movies only, small file sizes (720p/1080p) |

**Note:** Public indexers have more fake/low-quality uploads. Quality profiles help filter these out.

---

## Private Trackers (If You Have Access)

Private trackers offer better quality, speed, and fewer fakes:

| Indexer | Focus | Notes |
|---------|-------|-------|
| IPTorrents | General | Large, requires invite |
| TorrentLeech | General | Requires invite |
| FileList | General | Romanian, high quality |
| PassThePopcorn | Movies | Elite, hard to get into |
| BroadcasTheNet | TV | Elite, hard to get into |
| Orpheus | Music | If you also want music |

---

## Indexer Configuration Tips

### Categories

When adding indexers, enable appropriate categories:

**For Radarr (Movies):**
- Movies
- Movies/HD
- Movies/UHD
- Movies/BluRay
- Movies/WEB-DL

**For Sonarr (TV):**
- TV
- TV/HD
- TV/UHD
- TV/WEB-DL

### Priority

Set priority if you have multiple indexers (lower = tried first):

- **Priority 1-10:** Private trackers (faster, more reliable)
- **Priority 20-30:** Public trackers (fallback)

### Seed Ratio/Time

Configure in Prowlarr to match tracker requirements:

```
Minimum Seeders: 1
Seed Ratio: 1.0 (or tracker minimum)
Seed Time: 2880 (48 hours, or tracker minimum)
```

---

## Testing Indexers

### In Prowlarr

1. Go to **Indexers**
2. Click the indexer name
3. Click **Test** button
4. Check for green checkmark

### Manual Search

1. Go to **Search** in Prowlarr
2. Enter a known movie/show title
3. Verify results appear

### Check Sync to Apps

1. Go to **Settings → Apps**
2. Click **Sync App Indexers**
3. Verify indexers appear in Radarr/Sonarr

---

## Troubleshooting

### Indexer Shows Red/Unhealthy

```bash
# Check Prowlarr logs
docker logs prowlarr --tail 100 | grep -i error
```

Common issues:
- **Cloudflare protection:** Some indexers block automated access
- **Rate limiting:** Too many requests, wait and retry
- **Site down:** Check if the site is accessible in a browser
- **Credentials expired:** Re-enter username/password

### No Results in Searches

1. Check indexer is enabled and healthy
2. Verify categories are correctly mapped
3. Try searching directly in Prowlarr (not through Radarr/Sonarr)
4. Check if content exists on the indexer's website

### Indexers Not Appearing in Radarr/Sonarr

1. In Prowlarr: **Settings → Apps**
2. Click your app (Radarr/Sonarr)
3. Click **Test** - should show green
4. Click **Sync App Indexers**
5. Check Radarr/Sonarr: **Settings → Indexers**

---

## FlareSolverr (For Protected Indexers)

Some indexers use Cloudflare protection. FlareSolverr can bypass this.

### Add to docker-compose.yml

```yaml
flaresolverr:
  image: ghcr.io/flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  networks:
    - arrnet
  environment:
    - TZ=${TZ}
  ports:
    - 8191:8191
  restart: unless-stopped
```

### Configure in Prowlarr

1. **Settings → Indexers → Add** (under Indexer Proxies)
2. Select **FlareSolverr**
3. Host: `http://flaresolverr:8191`
4. Tag the indexers that need it

---

## Indexer Backup

Prowlarr config is backed up with appdata:

```
/srv/appdata/prowlarr/
├── config.xml          # Main config
├── prowlarr.db         # Database (indexers, history)
└── logs/
```

Export indexers manually:
1. **System → Backup**
2. Click **Backup Now**
3. Download the .zip file

---

## Adding a New Indexer Checklist

1. [ ] Add indexer in Prowlarr
2. [ ] Enter credentials/API key
3. [ ] Enable correct categories (Movies/TV)
4. [ ] Set appropriate priority
5. [ ] Click **Test** - verify green checkmark
6. [ ] Click **Save**
7. [ ] Go to **Settings → Apps → Sync App Indexers**
8. [ ] Verify appears in Radarr/Sonarr indexer settings
9. [ ] Do a test search in Radarr/Sonarr

---

## Monitoring Indexer Performance

Check which indexers are actually finding content:

**Prowlarr → Statistics:**
- Queries per indexer
- Grab success rate
- Average response time

Remove indexers that consistently fail or return no results.
