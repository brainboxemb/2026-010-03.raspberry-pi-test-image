# Setup guide — install Brainbox Zero

This is the main entry point for installing the Brainbox Zero image.

The development workstation is **Windows**. GitHub Actions builds the image; on Windows you only
download the built artifact, write it to the microSD card and add local device configuration.

For the partition layout, what the `.img.xz` actually contains, and the design for
future updates directly from the Pi prompt, see
[30 — SD layout and image updates](30-sd-layout-and-image-updates.md).
The present installation is still a fresh flash; on-device full-image replacement
is **not implemented**.

## Overview

```text
GitHub Actions
    |
    v
brainbox-zero.img.xz
    |
    | download on Windows
    v
flash microSD
    |
    v
add local user-data + network-config
    |
    v
Raspberry Pi first boot
    |
    +--> serial console
    +--> SSH
```

Credentials are **not** stored in GitHub and **not** embedded in the built image.

## Before you start

You need:

- a Raspberry Pi Zero / Zero W and a stable power supply;
- a microSD card (at least 8 GB; 16 GB or more is convenient) and a Windows card reader;
- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) installed on Windows;
- a local copy of this repository for the configuration examples and PowerShell script.

**You do not need to format the microSD card, create partitions, or copy Linux files manually.**
Raspberry Pi Imager writes the complete partition layout and filesystems from the image.
Writing an image **erases the entire microSD card**, so check the target drive carefully.

**Image choice:** the current GitHub build uses Raspberry Pi OS Lite (32-bit), not Alpine Linux.
Alpine is being evaluated separately; do not select Alpine or the stock Raspberry Pi OS image
in Imager when following these instructions.

## 1. Build the image on GitHub

For development, use the GitHub Actions artifact described below. For a tagged
`image-v*` build, the workflow also publishes the image and SHA-256 checksum as
a longer-lived GitHub Release; neither option provides on-device installation yet.

Open the repository on GitHub.

Go to:

```text
Actions
  -> Build Brainbox Zero image
  -> Run workflow
```

The workflow uses `config/image.env`, which contains the exact base image, download URL and
SHA-256.

After a successful build, the workflow run contains an artifact named:

```text
brainbox-zero
```

Download that artifact to the Windows workstation and extract the ZIP. It contains:

```text
*.img.xz
*.img.xz.sha256
```

## 2. Verify SHA-256 on Windows

Open PowerShell in the directory containing the downloaded image:

```powershell
Get-FileHash -Algorithm SHA256 .\<image>.img.xz
```

Compare the result with the matching `.sha256` file from the same build.

## 3. Prepare and write the microSD card (Windows)

1. Insert the microSD card into the Windows card reader. **Anything on this card will be erased.**
2. Open **Raspberry Pi Imager**.
3. Choose the OS: **Use custom** (sometimes under **Choose OS → Use custom**).
4. Select `brainbox-zero.img.xz` extracted from the GitHub Actions artifact. Do not pick a
   ready-made OS from the Imager list.
5. Choose the microSD card as the **storage** target. Double-check its size and drive before writing.
6. Start the write operation and allow Imager to verify the result.
7. If Imager offers OS customisation (hostname, username, Wi-Fi, SSH), **skip it**. We supply
   device-specific settings separately in steps 4 and 5 below.
8. When writing finishes, leave or reinsert the card in the reader so Windows can show its FAT
   boot partition. It may have a label such as `bootfs` and a drive letter such as `E:`.

**Important Windows detail:** Windows cannot normally read the Linux root partition. If Windows
asks to format an unrecognised partition after flashing, select **Cancel**. Never format it.

You should find files such as `config.txt`, `cmdline.txt` and
`brainbox-zero-config.txt` in the readable boot partition. The actual Linux installation lives
on the other partition, which does **not** need to be visible in Windows.
No extra formatting or manual partitioning is needed.

## 4. Prepare local device configuration

The repository contains examples:

```text
device-config/user-data.example
device-config/network-config.example
```

Create a local `local` directory:

```powershell
New-Item -ItemType Directory -Force .\local
Copy-Item .\device-config\user-data.example .\local\user-data
Copy-Item .\device-config\network-config.example .\local\network-config
```

`local/` is ignored by Git and must never be committed.

Edit the local files.

### local/user-data

This contains, for example:

- hostname;
- user account;
- local password for serial recovery;
- SSH public key;
- timezone.

### local/network-config

This contains:

- Wi-Fi country code;
- SSID;
- Wi-Fi password.

These files contain device-specific secrets and stay only on the local Windows workstation and,
after preparation, on the SD card.

## 5. Copy device configuration to the SD card

After flashing, identify the drive letter of the FAT **boot partition** in Windows Explorer.
Verify it contains `config.txt` before running the script; do not pass the Windows system drive.

For example, if Windows mounts it as `E:\`, run:

```powershell
.\scripts\Prepare-SdCard.ps1 -BootDrive E:\
```

The script copies:

```text
local/user-data       -> E:\user-data
local/network-config  -> E:\network-config
```

Check in Windows Explorer that both new files are present in the **root of the boot partition**,
next to `config.txt` (not in a subfolder). Safely eject the microSD card before inserting it
into the Pi.

The official Raspberry Pi OS Trixie image already contains the cloud-init support and `meta-data`
needed to process these files.

## 6. Connect the serial console

For first boot, preferably use the Raspberry Pi Debug Probe or another 3.3 V TTL USB-UART adapter.

| Raspberry Pi | UART |
| --- | --- |
| pin 6 — GND | GND |
| pin 8 — GPIO14 / TX | RX |
| pin 10 — GPIO15 / RX | TX |

Do not connect the UART adapter VCC pin when the Pi has its own power supply.

Terminal settings:

```text
115200 baud
8N1
no flow control
```

PuTTY can be used on Windows.

For details, see
[40 — Serial console and troubleshooting](40-headless-bring-up-and-serial-console.md).

## 7. First boot

Insert the microSD card and power on the Pi.

On first boot, cloud-init processes:

- `user-data`;
- `network-config`.

This creates the local user and configures SSH and Wi-Fi without those credentials ever being part
of the GitHub-built image.

The first boot can take longer than subsequent boots.

## 8. Check SSH

From PowerShell:

```powershell
ssh <username>@brainbox-zero-01.local
```

If mDNS does not resolve the hostname, use the Pi's IP address instead.

## 9. Verify the installed image

After logging in, run:

```bash
verify-brainbox-zero
```

The command reports the embedded base-image identity, Git commit, architecture, OS version and UART
mapping. The raw build identity is stored in:

```text
/etc/brainbox-zero-image
```

The image installation is successful when:

- the Pi boots normally;
- the serial console works;
- cloud-init processes the local device configuration;
- SSH works;
- `verify-brainbox-zero` completes.

That is the responsibility boundary of this repository. Application and benchmark verification
belong to the consuming repositories.
