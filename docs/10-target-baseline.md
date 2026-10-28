# 10 — Image baseline

## Purpose

This repository builds the reproducible Brainbox Zero image from a pinned official Raspberry Pi OS
base image.

The first physical target is a Raspberry Pi Zero W version 1. It therefore requires a 32-bit image
that can boot on this ARMv6-class Pi.

## Current base image

The active values are defined only in:

```text
config/image.env
```

It records at least:

- `IMAGE`;
- `IMAGE_URL`;
- `IMAGE_SHA256`.

Updating the base image is therefore an explicit repository change. The build verifies the
SHA-256 before using the downloaded image.

## Generic versus device-specific configuration

The GitHub-built Brainbox Zero image contains only generic platform configuration.

It does not contain:

- Wi-Fi SSID or password;
- user password;
- private SSH key;
- other device-specific secrets.

Those values are added after flashing as local cloud-init configuration on the FAT boot partition.

## Image identity

During the build, the root filesystem receives:

```text
/etc/brainbox-zero-image
```

It records at least the base image, base-image SHA-256, repository and Git commit. This makes it
possible to identify which image is actually installed after boot.
