# Hardware Notes

## System Specifications

### Intel NUC10i5FNH

| Component | Spec |
|-----------|------|
| CPU | Intel i5-10210U (4-Core, 8 Threads) |
| RAM | 16GB |
| Storage | 512GB m.2 SATA SSD |
| Graphics | Intel UHD Graphics |
| Connectivity | WiFi, Bluetooth, Gigabit Ethernet |
| Ports | HDMI, USB 3.1, SD Card |
| OS | Debian |

This NUC is well-suited for a media stack - plenty of CPU headroom for the Arr apps and hardware decoding if needed.

---

## Storage Configuration

### Attached USB Storage

Connected via powered USB hub:

| Mount | Drive | Capacity | Purpose |
|-------|-------|----------|---------|
| `/mnt/usb1` | 8TB | 8 TB | Movies + TV |
| `/mnt/usb2` | 8TB | 8 TB | Movies + TV |
| `/mnt/usb3` | 12TB | 12 TB | Movies + TV |
| `/mnt/usb4` | 12TB | 12 TB | Movies + TV |

**Total Storage:** 40TB raw

### Internal SSD (512GB)

| Path | Purpose |
|------|---------|
| `/` | OS, Docker |
| `/srv/appdata` | Container configs/databases |
| `/home/qbittorrent-nox/Downloads` | Active torrent downloads |

**Note:** Downloads happen on the fast SSD, then import to USB drives. This reduces wear on the external drives and speeds up seeding.

---

## USB Hub Requirements

With four large external drives, a powered USB hub is essential:

- **Use a powered hub** - The NUC's USB ports cannot power 4 drives
- **USB 3.0+** - For adequate transfer speeds
- **Individual port power** - Some hubs share power across ports

**Symptoms of power issues:**
- Drives disconnect randomly
- `dmesg | grep -i usb` shows reset errors
- Drives spin down unexpectedly

---

## Drive Identification

### List All Drives

```bash
# Block devices
lsblk

# With UUIDs (for fstab)
sudo blkid

# Detailed info
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT
```

### Current Mounts

```bash
mount | grep usb
df -h /mnt/usb*
```

---

## Formatting a New/Replacement Drive

```bash
# 1. Identify the device (e.g., /dev/sdb)
lsblk

# 2. Create partition table and partition
sudo fdisk /dev/sdb
# g (GPT table for >2TB), n (new), 1, Enter, Enter, w (write)

# 3. Format as ext4 with label
sudo mkfs.ext4 -L usb3 /dev/sdb1

# 4. Get UUID for fstab
sudo blkid /dev/sdb1
```

---

## Persistent Mounts (fstab)

Edit `/etc/fstab` for automatic mounting at boot:

```bash
sudo nano /etc/fstab
```

Add entries using UUID (survives drive letter changes):

```fstab
# Media drives - nofail allows boot if drive is missing
# x-systemd.device-timeout prevents long boot delays

# 8TB Drives
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /mnt/usb1 ext4 defaults,nofail,x-systemd.device-timeout=30 0 2
UUID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy /mnt/usb2 ext4 defaults,nofail,x-systemd.device-timeout=30 0 2

# 12TB Drives
UUID=zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz /mnt/usb3 ext4 defaults,nofail,x-systemd.device-timeout=30 0 2
UUID=wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww /mnt/usb4 ext4 defaults,nofail,x-systemd.device-timeout=30 0 2
```

Test without rebooting:

```bash
sudo mount -a
df -h /mnt/usb*
```

---

## Drive Permissions

```bash
# Create media group if needed
sudo groupadd -g 1002 media

# Set ownership on mount points
sudo chown -R root:media /mnt/usb1 /mnt/usb2 /mnt/usb3 /mnt/usb4
sudo chmod -R 2775 /mnt/usb1 /mnt/usb2 /mnt/usb3 /mnt/usb4

# Create and set ownership on media directories
sudo mkdir -p /mnt/usb{1,2,3,4}/movies /mnt/usb{1,2,3,4}/tv
sudo chown -R 1000:media /mnt/usb{1,2,3,4}/movies /mnt/usb{1,2,3,4}/tv
sudo chmod -R 2775 /mnt/usb{1,2,3,4}/movies /mnt/usb{1,2,3,4}/tv
```

The `2775` permission sets the setgid bit, ensuring new files inherit the `media` group.

---

## Downloads Directory

### Location

```
/home/qbittorrent-nox/Downloads/
```

On the internal SSD for fast I/O during active downloads.

### Permissions

```bash
# Verify
ls -la /home/qbittorrent-nox/

# Should show: drwxrwsr-x (2775) with media group

# Fix if needed
sudo chown -R 1000:media /home/qbittorrent-nox/Downloads
sudo chmod 2775 /home/qbittorrent-nox/Downloads
```

---

## Checking Drive Health

### SMART Status

```bash
sudo apt install smartmontools

# Quick health check
sudo smartctl -H /dev/sda

# Full SMART data
sudo smartctl -a /dev/sda

# Run short self-test (takes ~2 minutes)
sudo smartctl -t short /dev/sda

# Run long self-test (takes hours, for thorough check)
sudo smartctl -t long /dev/sda

# Check test results
sudo smartctl -l selftest /dev/sda
```

### Check All Drives

```bash
for drive in sda sdb sdc sdd; do
  echo "=== /dev/$drive ==="
  sudo smartctl -H /dev/$drive
done
```

### Key SMART Attributes to Watch

| Attribute | Warning Sign |
|-----------|--------------|
| Reallocated_Sector_Ct | Any value > 0 |
| Current_Pending_Sector | Any value > 0 |
| Offline_Uncorrectable | Any value > 0 |
| UDMA_CRC_Error_Count | Increasing = cable/connection issue |
| Power_On_Hours | For age tracking |

---

## Filesystem Check

Only run on unmounted filesystems:

```bash
# Unmount first
sudo umount /mnt/usb1

# Check and repair
sudo fsck -f /dev/sda1

# Remount
sudo mount /mnt/usb1
```

---

## Drive Failure Recovery

### If a Drive Dies

1. **Don't panic** - Radarr/Sonarr track your library, not the files
2. Check which drive failed: `lsblk`, `dmesg | tail -50`
3. Stop the stack: `docker compose down`
4. Replace the drive
5. Format with same label/mount point
6. Update fstab with new UUID
7. Mount and set permissions
8. Restart stack
9. In Radarr/Sonarr, rescan or trigger re-download of missing content

### Spreading Content Across Drives

Radarr and Sonarr support multiple root folders. Configure in each app:

**Radarr:** Settings → Media Management → Root Folders
```
/mnt/usb1/movies (8TB)
/mnt/usb2/movies (8TB)
/mnt/usb3/movies (12TB)
/mnt/usb4/movies (12TB)
```

**Sonarr:** Settings → Media Management → Root Folders
```
/mnt/usb1/tv (8TB)
/mnt/usb2/tv (8TB)
/mnt/usb3/tv (12TB)
/mnt/usb4/tv (12TB)
```

When adding content, select which root folder to use. Larger drives (12TB) can hold more.

---

## Network Configuration

### Static IP (Recommended)

Set a static IP so services are always reachable at the same address.

**Edit /etc/network/interfaces (Debian):**

```bash
sudo nano /etc/network/interfaces
```

```
# Loopback
auto lo
iface lo inet loopback

# Primary network interface
auto eno1
iface eno1 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1 8.8.8.8
```

```bash
sudo systemctl restart networking
```

**Or using NetworkManager (if installed):**

```bash
nmcli con show
nmcli con mod "Wired connection 1" ipv4.addresses 192.168.1.100/24
nmcli con mod "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli con mod "Wired connection 1" ipv4.dns "192.168.1.1 8.8.8.8"
nmcli con mod "Wired connection 1" ipv4.method manual
nmcli con up "Wired connection 1"
```

### Use Ethernet, Not WiFi

The NUC has WiFi, but for a media server:
- Use Gigabit Ethernet for reliability
- WiFi adds latency and can drop under load
- Large file transfers will saturate WiFi

---

## Power Management

### Disable USB Autosuspend

Prevent drives from spinning down unexpectedly:

```bash
# Temporary (until reboot)
for device in /sys/bus/usb/devices/*/power/autosuspend; do
  echo -1 | sudo tee $device
done

# Permanent - add to /etc/rc.local or create udev rule
sudo nano /etc/udev/rules.d/50-usb-autosuspend.rules
```

```
ACTION=="add", SUBSYSTEM=="usb", ATTR{power/autosuspend}="-1"
```

```bash
sudo udevadm control --reload-rules
```

### UPS Recommendation

A small UPS protects against power outages:
- Prevents filesystem corruption on external drives
- Allows clean shutdown via NUT (Network UPS Tools)
- 600VA+ UPS sufficient for NUC + USB hub + drives

---

## Monitoring

### CPU Temperature

```bash
# Install sensors
sudo apt install lm-sensors
sudo sensors-detect

# Read temperatures
sensors
```

### Continuous Monitoring

```bash
watch -n 5 sensors
```

### System Resources

```bash
# Overall usage
htop

# Disk I/O
iotop

# Network
iftop
```

---

## NUC-Specific Notes

### BIOS Settings

For a headless media server, consider:
- **Boot on Power** - Auto-start after power loss
- **Wake on LAN** - Remote wake capability
- **Disable unused devices** - SD card reader, audio if not needed

### Headless Operation

If running without a monitor:
- SSH access: `ssh user@192.168.1.100`
- Portainer or Dozzle for container management
- Homarr dashboard for quick status

### Noise

The NUC10 fan can be audible under load. If noise matters:
- BIOS fan curve adjustments
- Ensure good ventilation
- The i5-10210U runs cool, fan rarely spins up with this workload
