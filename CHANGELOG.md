# Changelog

## Unreleased

- Bootstrap the reproducible Brainbox Zero Raspberry Pi platform image.
- Pin the official Raspberry Pi OS Lite 32-bit base image by URL and SHA-256.
- Build `brainbox-zero.img.xz` in GitHub Actions from versioned bootfs/rootfs overlays.
- Enable generic UART, I2C and SPI configuration in the built image.
- Keep Wi-Fi credentials, user passwords and SSH credentials outside the built image.
- Add local cloud-init examples and a Windows helper for device-specific first-boot configuration.
- Add a Windows-first installation/first-boot manual and serial-console recovery guide.
- Keep experiment workloads, benchmark execution and target-performance evidence outside this repository.
