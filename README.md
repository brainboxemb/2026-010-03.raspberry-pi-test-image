# Brainbox Zero

This repository builds **Brainbox Zero**, a reusable Raspberry Pi Zero platform image. Event Timing is currently one consumer of the platform.

## What this repository does

GitHub Actions:

1. downloads a pinned official Raspberry Pi OS Lite image;
2. verifies its SHA-256;
3. decompresses the image;
4. mounts the boot and root partitions;
5. applies the versioned overlays from this repository;
6. writes image identity information into the root filesystem;
7. recompresses the resulting image;
8. publishes the image and SHA-256 as a GitHub Actions artifact;
9. for `image-v*` tags only, publishes those verified files as a GitHub Release.

**Image updates from a running Pi are not supported yet**: whole-disk flashing must
be performed from another computer. See [SD layout and image update design](docs/30-sd-layout-and-image-updates.md).

The built image contains **no device-specific credentials**.

After flashing, hostname, user, SSH key and Wi-Fi configuration are added locally from the Windows
workstation to the FAT boot partition. Raspberry Pi OS processes those files on first boot through
cloud-init.

## Scope

This repository owns:

- official base-image selection and pinning;
- the Brainbox Zero image build;
- generic OS and boot configuration;
- the installation and first-boot procedure;
- Brainbox Zero image self-checks.

This repository does **not** own:

- experiment or benchmark software;
- performance verification;
- consumer application/domain logic;
- consumer-specific hardware/BOM/procurement;
- consumer-specific production-target qualification.

## Main files

- `config/image.env` — base image, URL and SHA-256;
- `overlay/bootfs/` — fixed files copied to the boot partition;
- `overlay/rootfs/` — fixed files copied to the Linux root filesystem;
- `device-config/` — examples for local first-boot configuration;
- `scripts/build-image.sh` — image build used by GitHub Actions;
- `scripts/Prepare-SdCard.ps1` — copies local device configuration to a flashed SD card;
- `.github/workflows/build-image.yml` — builds and publishes the image artifact;
- `docs/SETUP.md` — practical Windows-first setup guide.
- `docs/30-sd-layout-and-image-updates.md` — current SD-card partitions and proposed
  safe on-device image replacement (A/B slots; not yet implemented);

## Start here

Go to **[docs/SETUP.md](docs/SETUP.md)** for the first installation.

See **[docs/ROADMAP.md](docs/ROADMAP.md)** for the phased plan: first a basic
Raspberry Pi OS image; later optional USB-disk and GitHub-sourced updates.
