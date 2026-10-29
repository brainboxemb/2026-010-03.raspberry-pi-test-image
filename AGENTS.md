# AGENTS.md

## Purpose

This repository owns the reproducible Brainbox Zero Raspberry Pi platform image build and installation procedure. Event Timing is currently a consumer, not part of the image identity.

## Boundaries

Own here:

- official base-image selection, URL and SHA-256;
- GitHub Actions image build;
- bootfs/rootfs overlays;
- Brainbox Zero OS/runtime configuration that belongs in the image;
- first-boot/recovery access required to install and support the image;
- local cloud-init examples for device-specific configuration;
- image self-verification.

Do not own here:

- experiment workloads or benchmark runners;
- performance measurement or benchmark result storage;
- consumer application/domain code;
- target hardware BOM/procurement;
- consumer-specific production-target selection.

## Engineering rules

- Build from an official supported Raspberry Pi OS image rather than inventing a distribution.
- Pin the base image by explicit URL and SHA-256.
- Keep the GitHub-built image free of Wi-Fi passwords, user passwords, private SSH keys and other
  device-specific secrets.
- Device-specific first-boot configuration is applied locally after flashing via cloud-init files
  on the FAT boot partition.
- Image verification checks installation only; it must not execute consumer test software.
- Never commit files under `local/`.
