# 20 — Image build and setup

## Build model

The repository uses a simple derived-image build:

```text
official Raspberry Pi OS Lite .img.xz
        +
SHA-256 verification
        +
overlay/bootfs
        +
overlay/rootfs
        +
small explicit image patches
        =
Brainbox Zero
```

This repository does not build a custom Linux distribution and does not contain an experiment
runner.

## Base image

`config/image.env` contains:

```bash
IMAGE=...
IMAGE_URL=...
IMAGE_SHA256=...
```

`scripts/build-image.sh` downloads exactly that image and stops if the SHA-256 does not match.

## Boot overlay

Everything under:

```text
overlay/bootfs/
```

is copied to the FAT boot partition.

The Brainbox Zero boot configuration currently lives in `brainbox-zero-config.txt`, which is
included from `config.txt`.

Device-specific secrets must not be stored here.

## Root filesystem overlay

Everything under:

```text
overlay/rootfs/
```

is copied to the Linux root filesystem.

This is where fixed image-owned files can live, for example systemd units, scripts or runtime files
that are part of the image itself.

## Device configuration through cloud-init

Raspberry Pi OS Trixie supports cloud-init through files on the FAT boot partition.

After flashing, the Windows workstation adds:

```text
user-data
network-config
```

This is deliberately **outside the GitHub image build**.

Examples are stored under `device-config/`; real device-specific files live locally under
`local/`.

## GitHub Actions

`.github/workflows/build-image.yml` builds the image on an Ubuntu runner and publishes:

- the compressed `.img.xz`;
- a SHA-256 file.

The workflow can be started manually and is also run for image-related pull-request changes. Image
release tags can be used later when a retained release artifact is needed.

## Responsibility boundary

This repository verifies only that the image can be built and installed correctly.

Application software, experiments, benchmarks and performance qualification belong to the consuming repositories.
