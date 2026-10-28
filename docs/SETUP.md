# Setup guide — install Brainbox Zero

This is the main entry point for installing the Brainbox Zero image.

The development workstation is **Windows**. GitHub Actions builds the image; on Windows you only
download the built artifact, write it to the microSD card and add local device configuration.

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

## 1. Build the image on GitHub

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

## 3. Write the image to microSD

Use Raspberry Pi Imager only as the **image writer**:

1. insert the microSD card;
2. open Raspberry Pi Imager;
3. choose `Use custom`;
4. select the GitHub-built `.img.xz`;
5. select the correct microSD card;
6. write and verify the card.

Do **not** use Raspberry Pi Imager customisation for users, Wi-Fi or SSH. Device-specific
configuration is added explicitly in the next step.

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

After flashing, the FAT boot partition is visible in Windows.

For example, if Windows mounts it as `E:\`, run:

```powershell
.\scripts\Prepare-SdCard.ps1 -BootDrive E:\
```

The script copies:

```text
local/user-data       -> E:\user-data
local/network-config  -> E:\network-config
```

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
