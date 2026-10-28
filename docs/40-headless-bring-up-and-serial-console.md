# 40 — Serial console and troubleshooting

This page is reference material for the Raspberry Pi serial connection. For the normal installation
flow, start with [SETUP.md](SETUP.md).

## Why use a serial console?

The Pi is used headlessly. Normally you log in through SSH, but SSH is not useful when Wi-Fi, DHCP
or the SSH service itself is unavailable.

Therefore the setup has two independent access paths:

```text
normal:      network -> SSH
recovery:    GPIO UART -> USB serial -> Windows PC
```

The serial connection can also show boot messages before networking is available.

## What the image already configures

The GitHub-built Brainbox Zero image enables:

```text
enable_uart=1
```

and adds the following to `cmdline.txt`:

```text
console=serial0,115200
```

No manual editing should be required after a normal flash.

## Wiring

Use a **3.3 V TTL UART** adapter, for example the Raspberry Pi Debug Probe.

Do not use 5 V TTL signalling.

| Raspberry Pi | Function | USB-UART |
| --- | --- | --- |
| pin 6 | GND | GND |
| pin 8 | GPIO14 / TX | RX |
| pin 10 | GPIO15 / RX | TX |

TX and RX cross over:

```text
Pi TX  -> adapter RX
Pi RX  <- adapter TX
Pi GND -- adapter GND
```

### Do not connect the adapter power pin

Power the Pi through its normal power connector.

For debugging, connect only:

- GND;
- TX;
- RX.

Do not connect the adapter 5 V or 3.3 V power pin. This avoids back-powering the Pi and keeps the
power path unambiguous.

## Windows: find the COM port

1. connect the USB-UART adapter or Debug Probe;
2. open **Device Manager**;
3. look under **Ports (COM & LPT)**;
4. note the assigned COM port, for example `COM5`.

The COM port can change if the adapter is moved to a different USB port.

## Configure PuTTY

Use:

```text
115200 baud
8 data bits
no parity
1 stop bit
no flow control
```

Short form:

```text
115200 8N1
```

In PuTTY:

1. choose **Serial**;
2. Serial line: for example `COM5`;
3. Speed: `115200`;
4. Flow control: `None`;
5. open the connection;
6. only then power on or reboot the Pi.

If you want to see the earliest normal boot messages, the terminal must already be open before
power-on.

## Expected behaviour

A normal boot should show Linux/systemd boot output and eventually a login prompt.

| Observation | Check first |
| --- | --- |
| no serial output at all | COM port, GND/TX/RX, 3.3 V logic, UART config, SD/image |
| boot log appears but networking fails | Wi-Fi/cloud-init/DHCP |
| boot completes but SSH fails | SSH configuration, key, network |
| kernel panic/filesystem errors | image or microSD |
| repeated resets/undervoltage | power supply |

## If there is no serial output

Insert the microSD card back into the Windows workstation. The FAT boot partition is directly
readable.

Verify that `config.txt` includes:

```text
include brainbox-zero-config.txt
```

Verify that `brainbox-zero-config.txt` contains:

```text
enable_uart=1
```

Verify that `cmdline.txt` remains **one line** and contains:

```text
console=serial0,115200
```

Use `serial0`; do not hard-code `ttyAMA0` or `ttyS0`.

## After login

Run the installed image self-check first:

```bash
verify-brainbox-zero
```

For additional diagnostics:

```bash
uname -a
uname -m
cat /etc/os-release
readlink -f /dev/serial0
systemctl status serial-getty@serial0.service --no-pager || true
ip address
```

The self-check only verifies the installed image. Application and benchmark verification belongs to
the consuming repository.

## Pi Zero W and serial0

The physical header remains:

```text
GPIO14 = TX
GPIO15 = RX
```

but the internal UART behind `serial0` can differ by Pi model. Always use the stable alias:

```text
/dev/serial0
```

and for the boot console:

```text
console=serial0,115200
```

This keeps the procedure independent of `ttyAMA0` versus `ttyS0`.

## Very early boot problems

Do not enable `earlycon` by default.

It is only useful when a failure happens before the normal Linux console becomes active, and the
parameter depends on the exact model/UART. An incorrect `earlycon` definition can itself cause
boot problems.

Older Raspberry Pi models also support firmware/bootcode UART diagnostics. Treat that as a
troubleshooting technique for a specific very-early-boot problem, not part of the normal image.

## First-boot checklist

Before power-on:

- [ ] microSD contains the GitHub-built image;
- [ ] local `user-data` and `network-config` are present on bootfs;
- [ ] USB-UART uses 3.3 V logic;
- [ ] GND is connected;
- [ ] Pi pin 8 TX goes to adapter RX;
- [ ] Pi pin 10 RX comes from adapter TX;
- [ ] adapter VCC is not connected;
- [ ] PuTTY is configured for 115200 8N1 with no flow control;
- [ ] PuTTY is open before power-on.

After boot:

- [ ] boot messages are visible;
- [ ] serial login works;
- [ ] `verify-brainbox-zero` works;
- [ ] networking is active;
- [ ] SSH login works;
- [ ] a normal reboot restores both serial console and SSH access.
