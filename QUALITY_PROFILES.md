# Quality Profiles (Recyclarr)

## Overview

Recyclarr syncs quality profiles and custom formats from the [TRaSH Guides](https://trash-guides.info/) to Radarr and Sonarr automatically.

**Sync Schedule:** Daily at 3:30 AM (configured via `CRON_SCHEDULE`)

**Config Location:** `srv/compose/arr/recyclarr/configs/`

---

## Current Quality Profiles

### Movies (Radarr)

| Profile | Upgrades | Max Quality | Use For |
|---------|----------|-------------|---------|
| Movies-720p | No | Bluray-720p | Low bandwidth, small files |
| Movies-1080p | Yes | Bluray-1080p | Standard quality |
| Movies-2160p | Yes | Bluray-2160p | 4K content |

### TV (Sonarr)

| Profile | Upgrades | Max Quality | Use For |
|---------|----------|-------------|---------|
| TV-720p | No | Bluray-720p | Low bandwidth, small files |
| TV-1080p | Yes | Bluray-1080p | Standard quality |
| TV-2160p | Yes | Bluray-2160p | 4K content |

---

## Quality Hierarchy

From lowest to highest:

```
HDTV-720p (TV only)
    ↓
WEBRip-720p
    ↓
WEBDL-720p
    ↓
Bluray-720p
    ↓
HDTV-1080p (TV only)
    ↓
WEBRip-1080p
    ↓
WEBDL-1080p
    ↓
Bluray-1080p
    ↓
WEBRip-2160p
    ↓
WEBDL-2160p
    ↓
Bluray-2160p
```

With upgrades enabled, content automatically upgrades when better quality is found.

---

## Custom Formats Explained

Custom formats score releases to prefer/avoid certain characteristics.

### Preferred (Positive Scores)

| Format | Why |
|--------|-----|
| HDR | Better dynamic range on supported displays |
| HDR10Plus | Enhanced HDR metadata |
| Remaster | Improved versions of older films |
| 4K Remaster | 4K scan of original film elements |
| Criterion Collection | High-quality curated releases |
| IMAX / IMAX Enhanced | Expanded aspect ratio |
| Bluray Tier 1-3 | Ranked release groups (Tier 1 = best) |
| WEB Tier 1-3 | Ranked web release groups |
| Streaming Services | Properly tagged source (AMZN, NF, etc.) |

### Blocked (Negative Scores: -10000)

| Format | Why Blocked |
|--------|-------------|
| x265 (HD) | x265 at 720p/1080p offers poor quality vs file size |
| DV (Disk) | Dolby Vision profile that requires specific hardware |
| DV (w/o HDR fallback) | DV without HDR fallback is unplayable on most devices |
| AV1 | Codec not widely supported yet |
| BR-DISK | Full disc rips, massive files, often problematic |
| Upscaled | Fake 4K, actually lower resolution upscaled |
| 3D | 3D versions (only in Radarr) |

### Avoided (Negative Scores)

| Format | Score | Why |
|--------|-------|-----|
| LQ | -10000 | Low quality release groups |
| LQ (Release Title) | -10000 | Releases with LQ indicators in title |
| Bad Dual Groups | Varies | Known problematic release groups |
| Extras | -10000 | Behind-the-scenes, deleted scenes only |

---

## Why Block x265 at HD?

x265 (HEVC) is great for 4K/HDR content but problematic at 720p/1080p:

1. **Encoding overhead** - At lower resolutions, x265 doesn't save much space
2. **Quality loss** - Many HD x265 encodes over-compress
3. **Compatibility** - Older devices struggle with x265 decoding
4. **Re-encoding artifacts** - Often transcoded from x264, adding quality loss

**Exception:** x265 is NOT blocked at 2160p where it makes sense.

---

## Why Block Dolby Vision?

Dolby Vision is blocked unless it has HDR10 fallback because:

1. **DV (Disk)** - Profile 7, requires specific hardware/software
2. **DV without fallback** - Unplayable on non-DV displays

If your setup fully supports Dolby Vision, you can remove these blocks.

---

## Streaming Service Tags

These help identify the source and don't affect scoring much, but provide useful metadata:

| Tag | Service |
|-----|---------|
| AMZN | Amazon Prime Video |
| NF | Netflix |
| DSNP | Disney+ |
| HMAX / MAX | HBO Max |
| ATVP | Apple TV+ |
| PCOK | Peacock |
| HULU | Hulu |
| PMTP | Paramount+ |

---

## Modifying Profiles

### Edit Config Files

```bash
nano srv/compose/arr/recyclarr/configs/radarr.yml
nano srv/compose/arr/recyclarr/configs/sonarr.yml
```

### Force Sync After Changes

```bash
docker exec recyclarr recyclarr sync
```

### Check Sync Output

```bash
docker logs recyclarr --tail 50
```

---

## Common Modifications

### Allow x265 at 1080p

Remove or comment out the x265 (HD) block in both configs:

```yaml
# In radarr.yml and sonarr.yml, remove or comment:
# - trash_ids:
#     - dc98083864ea246d05a42df0d05f81cc  # x265 (HD)
#   assign_scores_to:
#     - name: Movies-1080p
#       score: -10000
```

### Allow Dolby Vision

Remove DV blocks:

```yaml
# Remove this entire block:
# - trash_ids:
#     - b337d6812e06c200ec9a2d3cfa9d20a7  # DV Boost
#     - f700d29429c023a5734505e77daeaea7  # DV (Disk)
#     - 923b6abef9b17f937fab56cfcf89e1f1  # DV (w/o HDR fallback)
#   assign_scores_to: ...
```

### Add a New Quality Profile

Add under `quality_profiles:` section:

```yaml
- name: Movies-Archive
  upgrade:
    allowed: false
  qualities:
    - name: WEBDL-1080p
    - name: WEBRip-1080p
```

### Change Upgrade Cutoff

Modify `until_quality`:

```yaml
- name: Movies-1080p
  upgrade:
    allowed: true
    until_quality: WEBDL-1080p  # Stop upgrading at WEBDL, don't wait for Bluray
```

---

## Understanding Trash IDs

Each custom format has a unique trash_id (hash). Find IDs at:
- [TRaSH Guides - Radarr Custom Formats](https://trash-guides.info/Radarr/Radarr-collection-of-custom-formats/)
- [TRaSH Guides - Sonarr Custom Formats](https://trash-guides.info/Sonarr/sonarr-collection-of-custom-formats/)

Or use Recyclarr to list them:

```bash
docker exec recyclarr recyclarr list custom-formats radarr
docker exec recyclarr recyclarr list custom-formats sonarr
```

---

## Release Group Tiers

Recyclarr ranks release groups by quality:

### Bluray Tiers (Best to Good)

| Tier | Groups (Examples) |
|------|-------------------|
| Tier 1 | FraMeSToR, HiFi, CtrlHD |
| Tier 2 | DON, EbP, NTb |
| Tier 3 | Most other P2P groups |

### WEB Tiers (Best to Good)

| Tier | Groups (Examples) |
|------|-------------------|
| Tier 1 | FLUX, CMRG, CAKES |
| Tier 2 | PECULATE, SiGMA |
| Tier 3 | Scene groups |

Higher tiers get positive scores, preferring them over lower tiers.

---

## Checking Applied Formats

In Radarr/Sonarr, check what formats are detected:

1. Go to a movie/show
2. Click **History** or **Activity**
3. Look at **Custom Formats** column

Or check the release before grabbing:
1. **Wanted → Manual Search**
2. Expand a result to see matched custom formats

---

## Config File Reference

### radarr.yml Structure

```yaml
radarr:
  movies:                              # Instance name
    base_url: http://radarr:7878       # Radarr URL (internal Docker network)
    api_key: !env_var RADARR_API_KEY   # From environment variable

    delete_old_custom_formats: true    # Remove formats not in config
    replace_existing_custom_formats: true

    quality_profiles:                  # Define quality tiers
      - name: Movies-1080p
        upgrade:
          allowed: true
          until_quality: Bluray-1080p
        qualities:
          - name: WEBRip-720p
          - name: WEBDL-720p
          # ... more qualities

    custom_formats:                    # Scoring rules
      - trash_ids:
          - abc123...                  # Format ID
        assign_scores_to:
          - name: Movies-1080p         # Apply to this profile
            score: 100                 # Optional custom score
```

---

## Backup Profiles

Quality profiles are stored in the app databases:

```
/srv/appdata/radarr/radarr.db
/srv/appdata/sonarr/sonarr.db
```

These are backed up with your regular appdata backups.

To export current profiles for documentation:

**Radarr:** System → Backup → Backup Now
**Sonarr:** System → Backup → Backup Now
