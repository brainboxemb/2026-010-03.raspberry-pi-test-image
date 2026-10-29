# 30 — SD-card layout and image updates

This page explains the **standard Raspberry Pi OS Lite image** used by Brainbox Zero
today, and the design needed for future updates from the running Raspberry Pi prompt.

**Status (2026-10-29):** the two-partition image and Windows flashing procedure are
implemented. **On-device replacement of the entire OS image is not implemented.**
The A/B design below is a proposal, not an installation procedure.

## 1. What an image file actually is

The build publishes `brainbox-zero.img.xz`. This is an XZ-compressed, **whole-disk**
image, not a directory of files and not a file to copy onto a FAT partition.

```text
brainbox-zero.img.xz
  (decompress)
brainbox-zero.img
    MBR partition table
    Partition 1: FAT boot filesystem
    Partition 2: ext4 Linux root filesystem
```

A generic imaging tool (for example USBImager, balenaEtcher or Raspberry Pi
Imager in "Use custom" mode) writes the uncompressed bytes to the SD card.
**Flashing replaces the partition table and partitions already on the card.**
There is no `brainbox-zero.img` file left *inside* the SD card afterwards.

## 2. Current SD layout: Raspberry Pi OS Lite

```text
SD card (for example 16 GB)
  |
  +-- MBR (partition table)
  |
  +-- p1  bootfs  FAT   [firmware, kernel, configuration]
  |       bootcode.bin / start*.elf / fixup*.dat (model-dependent)
  |       config.txt
  |       cmdline.txt
  |       kernel*.img and *.dtb / overlays
  |       brainbox-zero-config.txt
  |       user-data, network-config   <-- added locally after flashing
  |
  +-- p2  rootfs  ext4  [the operating system]
          /etc, /usr, /var, /home, ...
          /etc/brainbox-zero-image
          /usr/local/bin/verify-brainbox-zero
  |
  +-- unallocated space until the root partition expands on first boot
      (if the flashed image is smaller than the SD card)
```

The *exact* sizes, boot file names and PARTUUIDs come from the pinned official
base image (`config/image.env`); they are **not fixed by our overlay build**.
Never assume that the illustrated sizes or partition numbers are a promise
for future images.

On a running Raspberry Pi OS system:

- the ext4 root filesystem is mounted at `/`;
- the FAT boot filesystem is mounted at `/boot/firmware`;
- the boot firmware reads `config.txt` from FAT;
- `cmdline.txt` passes the root partition identifier to the kernel
  (often `root=PARTUUID=...`);
- the kernel mounts rootfs and starts the OS.

Windows can normally read the FAT boot partition. It cannot natively read
the ext4 root partition; **do not format** a partition Windows does not recognise.

### Inspect the real card from the Pi

All commands below are read-only:

```sh
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTUUID,MOUNTPOINTS
findmnt -no SOURCE,FSTYPE,TARGET /
findmnt -no SOURCE,FSTYPE,TARGET /boot/firmware
cat /proc/cmdline
df -h / /boot/firmware
cat /etc/brainbox-zero-image
```

Use `lsblk` to establish the *actual* device (often `/dev/mmcblk0`).
Do not hard-code the device number in scripts that write storage.

## 3. Initial installation vs OS maintenance vs image replacement

These are different operations:

| Operation | Where it runs | Currently available? | What changes |
| --- | --- | --- | --- |
| First flash | Windows/Linux/macOS PC with SD reader | Yes | Whole SD card, including partitions |
| Package update | Running Raspberry Pi, `apt` | Normal Raspberry Pi OS operation | Packages on the running root filesystem |
| Replace complete Brainbox Zero image | Running Raspberry Pi | **No** | Boot + root filesystem; requires an update design |

Normal package maintenance on the current Debian-based installation:

```sh
sudo apt update
sudo apt full-upgrade
sudo reboot
```

This **does not install a new GitHub-built `brainbox-zero.img.xz`**. It
updates packages *in place*, so it is a different kind of maintenance.

**Do not run `dd` against `/dev/mmcblk0` from the Pi booted from that same
card.** The root filesystem and boot files would be overwritten while in use,
and a partial write can leave the device unbootable. Also, re-flashing the
current two-partition image would erase locally configured credentials.

## 4. Desired prompt-based workflow

The requested user experience is a simple command on the **running Pi**:

```sh
# DESIGN TARGET — these commands do not exist yet
sudo brainbox-zero update check
sudo brainbox-zero update install latest
```

With an optional explicit version:

```sh
# DESIGN TARGET — not yet implemented
sudo brainbox-zero update install image-v1.2.0
```

Expected behaviour:

1. Read a stable GitHub Release manifest (not a short-lived Actions artifact).
2. Check the target hardware/architecture and available space.
3. Download the **correct update payload** to a safe staging location.
4. Verify cryptographic integrity (SHA-256); plan independent manifest
   authentication/signatures for production.
5. Install the update to an **inactive system slot**, never to the live root.
6. Boot the new system once for testing.
7. Run a health check; commit the new slot only on success.
8. On a failed boot or failed health check, return to the previously working slot.
9. Preserve device-specific settings, SSH host keys and Wi-Fi credentials.

A downloaded **whole-disk** `.img.xz` cannot be written directly to the same
live SD card for this workflow. It contains a partition table and would also
overwrite the storage that is intended to survive updates. The future release
must publish a slot-specific update artifact in addition to the factory image.

## 5. Proposed future layout: A/B update slots

A candidate layout (not yet built or tested on Pi Zero W):

```text
SD card
  p1 BOOT_CONTROL (FAT)  boot selector / autoboot.txt
  p2 BOOT_A       (FAT)  firmware + kernel for system A
  p3 BOOT_B       (FAT)  firmware + kernel for system B
  p4 ROOT_A       (ext4) Linux installation A
  p5 ROOT_B       (ext4) Linux installation B
  p6 DATA         (ext4) persistent device config, keys, logs as needed
```

These are **logical roles**, not an approved MBR/GPT implementation.
In particular, an MBR has only four primary entries; the actual partition
table strategy (extended/logical partitions vs other compatible layout)
must be validated on the original Pi Zero W before building this image.

Two separately bootable slots avoid changing the active kernel/root pair
while installing a new image. A separate DATA area keeps per-device state
outside either OS image. Secrets must be accessible only to privileged users
on the running device; merely putting them on a FAT partition does not encrypt
or protect them.

### Possible Raspberry Pi boot mechanism

Raspberry Pi firmware documents `autoboot.txt` and one-shot `tryboot`
for selecting an alternate boot partition. The firmware's tryboot mechanism
is documented for all Pi models, but the full proposed layout and rollback
behaviour **still need hardware tests on the Pi Zero W**. Do not confuse this
with the Raspberry Pi Connect *remote A/B update service*, whose documented
recipient support starts at Pi 4.

A complete failure-safe updater additionally needs:

- a watchdog or reliable reboot trigger for a hung candidate system;
- an atomic/verified slot switch and explicit health criteria;
- a stable boot selector that is not accidentally replaced during updates;
- recovery from power loss during writing to the inactive slot;
- a first-boot setup path to populate persistent DATA from local config;
- an update payload that fits the inactive partitions;
- explicit compatibility rules for boot firmware and kernel changes;
- real on-device tests of success, rollback and interrupted updates.

## 6. Proposed implementation order

1. **Baseline (current):** keep the present Raspberry Pi OS Lite image and
   two-partition SD installation, and document the actual layout.
2. **Distribution:** publish versioned image files, checksums and metadata to
   stable GitHub Releases (Actions artifacts expire).
3. **A/B prototype:** validate boot slot selection and a rollback on a
   Raspberry Pi Zero W; choose a viable partition table and persistent DATA.
4. **Builder:** generate a factory SD image *and* a smaller slot-update
   artifact from the same pinned build.
5. **Updater:** implement `brainbox-zero update check/install` with hardware
   safeguards, verification and success/rollback logic.
6. **Validation:** test interrupted downloads, power loss, bad checksums,
   broken Wi-Fi, failed boots, and a full factory reflash/recovery path.

**Current limit:** the manual first-flash procedure in [SETUP.md](SETUP.md)
is still required. The image has **no on-device complete-image installer**
at present.

## References

- [Raspberry Pi: boot files and configuration](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [Raspberry Pi: `autoboot.txt`, `tryboot` and A/B design](https://www.raspberrypi.com/documentation/computers/config_txt.html#autoboottxt)
- [Raspberry Pi: fail-safe OS updates](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot)
- [Raspberry Pi Connect A/B remote update service (Pi 4+)](https://www.raspberrypi.com/documentation/services/connect.html)
