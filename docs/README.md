# Documentation

## Start here

**[SETUP.md](SETUP.md)** is the normal working path.

It describes, step by step:

1. building the image in GitHub Actions;
2. downloading the artifact;
3. writing the image to microSD;
4. adding local credentials;
5. performing the first boot;
6. checking the serial console and SSH.

## Reference

- [10 — Image baseline](10-target-baseline.md) — which base image is used;
- [20 — Image build and setup](20-image-build-and-setup.md) — how the derived image is built;
- [30 — SD layout and image updates](30-sd-layout-and-image-updates.md) — what is actually on the
  card, why flashing differs from updating, and the proposed on-device update command;
- [40 — Serial console and troubleshooting](40-headless-bring-up-and-serial-console.md) — UART and recovery.

Consumer-specific hardware, procurement, application software and benchmark execution do not belong in this image repository.
