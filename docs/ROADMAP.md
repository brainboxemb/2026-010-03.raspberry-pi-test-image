# Brainbox Zero — roadmap

Status: working plan, 2026-10-29. **Only the baseline image is in scope now.**
The later phases are ideas, not implementation commitments. Keep the platform
generic: it must not depend on the Event Timing application.

## Phase 1 — basic Raspberry Pi OS image (current)

**Goal:** a known, reproducible image that can be written to a fresh microSD
card, configured locally, and booted on a real Raspberry Pi Zero W.

- [x] Pin the official Raspberry Pi OS Lite 32-bit base image and SHA-256.
- [x] Build `brainbox-zero.img.xz` and its SHA-256 in GitHub Actions.
- [x] Include generic UART, SPI and I2C configuration and image identity.
- [x] Keep Wi-Fi passwords, local user credentials and private SSH keys out of
  Git and the downloadable image; provide local first-boot examples.
- [x] Document how to flash the microSD from Windows and set up first boot.
- [x] Provide `verify-brainbox-zero` for basic installed-image checks.
- [ ] Confirm the **latest** image build is green.
- [ ] Flash a real card and verify the **actual hardware boot**, local user,
  networking, SSH, serial console and image verification command.

**Done means:** a freshly prepared card boots into a usable platform image,
with device settings entered after flashing. No automatic OS update is required.

See [SETUP.md](SETUP.md) and
[SD-card layout](30-sd-layout-and-image-updates.md).

## Phase 2 — repeatable distribution

- Publish clearly versioned factory images with checksums in GitHub Releases.
- Confirm that tagged publishing works; the initial GitHub Actions workflow
  already includes a release-publishing step, but it is not a tested release.
- Record supported hardware and image version in a machine-readable format.
- Document how to recover by flashing a fresh SD card from another machine.

The **factory image** remains a whole-disk `.img.xz` and is intended for
initial installation or full recovery, not for overwriting the current system
from within that same running system.

## Phase 3 — decide the safe on-device update mechanism

Before implementing an update command, decide how boot, operating system
and persistent per-device configuration are separated. Evaluate:

- **A/B slots:** write a new OS to an inactive boot/root slot and switch to it,
  with health checks and rollback.
- **Recovery/initramfs updater:** reboot into a separate minimal environment
  before replacing the normal root filesystem; define safe recovery from a
  failed or interrupted installation.
- **Reflash from a different computer:** simple recovery path, but not an
  on-device update.

Do not assume A/B is already selected or supported by the current SD layout.
The existing two-partition Raspberry Pi OS Lite image stays unchanged
during Phase 1.

An on-device OS update must **not** directly `dd` a whole-disk image onto
the SD card that currently hosts the running root filesystem, and it must
not destroy Wi-Fi/SSH configuration.

## Phase 4 — install an update supplied on a USB disk (offline)

Use a **USB stick/disk as the source** for an update. A Raspberry Pi Zero W
needs a suitable USB-OTG adapter/hub when connecting USB mass storage to
its USB data port.

Example user experience (concept only; **not implemented**):

```sh
sudo brainbox-zero update install --file /media/usb/brainbox-zero-update.tar.xz
```

The same update engine as in Phase 3 verifies and installs the update. It is
**not** just copying the whole-disk image onto the currently mounted root
partition. A standard whole-disk factory image and a suitable on-device
update package may need to be two different artifacts.

This is useful when there is no Internet access, Wi-Fi setup is broken, or
we want to control exactly which version is installed.

## Phase 5 — download the update directly from GitHub (online)

Example user experience (concept only; **not implemented**):

```sh
sudo brainbox-zero update check
sudo brainbox-zero update install latest
sudo brainbox-zero update install image-v1.2.0
```

Download versioned, verified update packages from a stable GitHub Release.
Installation, compatibility checks, protection of persistent data, boot
selection and rollback should be **the same** as for USB. Only the update
source differs.

## Design principles

1. **First make the base image reliable.** Do not introduce update-specific
   partitioning or daemons into Phase 1.
2. **Separate the source from the installer.** USB and GitHub are two ways
   to supply the same validated update payload.
3. **Preserve local state.** Device identity, credentials and persistent data
   must have a defined survival path across updates.
4. **Recover from failure.** Test incomplete downloads, power cuts and bad
   kernels before calling the update mechanism production-ready.
5. **Keep choices open.** Alpine Linux and other distributions are separate
   investigations, not part of the current Raspberry Pi OS baseline.

Track future on-device updates in
[issue #3](https://github.com/brainboxemb/2026-010-03.raspberry-pi-test-image/issues/3).
