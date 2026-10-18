# NixOS for Smartwatches

<div align="center">
  <h1>⌚ NixOS for Smartwatches</h1>
  <p><em>Declarative, fully reproducible Linux operating system for wearable devices</em></p>
  <p>Combining the power of NixOS with the wearable UI and hardware adaptations pioneered by <a href="https://asteroidos.org/">AsteroidOS</a>.</p>
</div>

---

## Table of Contents

- [Overview](#overview)
- [Supported Devices](#supported-devices)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Building the OS Image](#building-the-os-image)
  - [Flashing via Fastboot](#flashing-via-fastboot)
- [System Updates over USB Gadget / SSH](#system-updates-over-usb-gadget--ssh)
  - [USB Networking Setup](#usb-networking-setup)
  - [Connecting via SSH](#connecting-via-ssh)
  - [Updating Live System Configurations](#updating-live-system-configurations)
- [Application Suite](#application-suite)
- [Architecture & Design](#architecture--design)
- [Acknowledgments](#acknowledgments)

---

## Overview

**NixOS for Smartwatches** brings declarative system configuration and atomic updates to wearable wrist hardware. Rather than retrofitting a mobile phone or desktop distribution onto a watch, this system is engineered specifically for wearable constraints:

- **Watch Display Forms**: Native support for circular screens (e.g. 400×400, 416×416, 454×454), square displays (e.g. 320×320), and round chin/"flat-tire" screens (e.g. 360×325).
- **Physical Controls**: Support for rotary encoder digital crowns, tactile hardware side buttons, and touch gestures.
- **Power & Thermals**: Always-On Display (AOD) ambient mode, OLED burn-in pixel shift, rapid suspend-to-RAM, and wrist thermal safety profiles.
- **Wearable User Experience**: Powered by `asteroid-launcher` (Wayland compositor with intuitive 4-way gesture navigation) and the `qml-asteroid` touch toolkit.

---

## Supported Devices

The following watches are supported across Qualcomm Snapdragon Wear, MediaTek, Exynos, and Broadcom SoC platforms:

| Device | Codename | SoC Platform | Display Type | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Fossil Gen 6** | `fossil-hoki` | Snapdragon Wear 4100+ | 416×416 Round AMOLED (Crown, AOD) | **Primary Reference** |
| **Fossil Gen 5** (Carlyle / Julianna) | `fossil-triggerfish` | Snapdragon Wear 3100 | 416×416 Round AMOLED (Crown, AOD) | Supported |
| **Fossil Gen 4** (Explorist HR) | `fossil-firefish` | Snapdragon Wear 2100 | 454×454 Round AMOLED (Crown) | Supported |
| **Google Pixel Watch 2** | `google-aurora` | Snapdragon W5 Gen 1 | 384×384 Round AMOLED (Crown, AOD) | Supported |
| **Mobvoi TicWatch Pro 3** | `ticwatch-rubyfish` | Snapdragon Wear 4100 | 454×454 Dual-Layer Round | Supported |
| **Mobvoi TicWatch Pro** | `ticwatch-catfish` | Snapdragon Wear 2100 | 400×400 Dual-Layer Round | Supported |
| **Huawei Watch 1** | `huawei-sturgeon` | Snapdragon 400 (APQ8026) | 400×400 Sapphire Round | Supported |
| **LG Watch Urbane** | `lg-bass` | Snapdragon 400 (APQ8026) | 320×320 P-OLED Round | Supported |
| **LG G Watch R** | `lg-lenok` | Snapdragon 400 (APQ8026) | 320×320 P-OLED Round | Supported |
| **ASUS ZenWatch 2** | `asus-sparrow` | Snapdragon 400 (APQ8026) | 320×320 Square AMOLED | Supported |
| **Moto 360 2nd Gen** | `motorola-smelt` | Snapdragon 400 (APQ8026) | 360×325 Round with Chin | Supported |
| **OPPO Watch 46mm** | `oppo-beluga` | Snapdragon Wear 3100 | 402×476 Curved Squircle | Supported |
| **QEMU x86_64 Emulator** | `uefi-x86_64` | Virtual x86_64 | Scalable Display | Development / VM |

---

## Quick Start

### Prerequisites

Ensure you have [Nix](https://nixos.org/download.html) installed with flakes or legacy nix-build support, and `fastboot` installed on your host machine:

```bash
# Ubuntu / Debian
sudo apt install android-tools-fastboot

# Fedora
sudo dnf install android-tools

# Arch Linux
sudo pacman -S android-tools
```

### Building the OS Image

Using our primary reference device, the **Fossil Gen 6** (`fossil-hoki`):

```bash
# Build the complete flashable smartwatch image
nix-build examples/asteroid --argstr device fossil-hoki -A outputs.default
```

Once the build finishes, the output artifacts will be linked in `./result`:

- `result/boot.img` – Android boot image containing the Linux kernel and stage-1 initramfs
- `result/userdata.img` (or `result/rootfs.img`) – Ext4 root filesystem containing the Nix store and system generation

### Flashing via Fastboot

1. Put your smartwatch into fastboot mode:
   - Power off the watch completely.
   - Hold down the power/crown button and middle button until the fastboot bootloader screen appears.
   - Alternatively, from ADB: `adb reboot bootloader`.

2. Connect the watch cradle/charging cable to your host PC via USB.

3. Verify connection:
   ```bash
   fastboot devices
   ```

4. Flash the boot and system partitions:
   ```bash
   # Flash the Linux kernel and initramfs
   fastboot flash boot result/boot.img

   # Flash the root filesystem image
   fastboot flash userdata result/userdata.img

   # Reboot into NixOS
   fastboot reboot
   ```

> [!NOTE]
> For devices utilizing Android Boot Header v4 (e.g. `google-aurora`), flash using `--slot=all`:
> ```bash
> fastboot flash --slot=all boot result/boot.img
> fastboot flash --slot=all vendor_kernel_boot result/vendor_kernel_boot.img
> fastboot flash --slot=all init_boot result/init_boot.img
> ```

---

## System Updates over USB Gadget / SSH

One of the key benefits of NixOS is atomic, rollback-capable system updates over the air or USB without needing to reflash partitions in fastboot.

### USB Networking Setup

When booted, the smartwatch automatically exposes a USB Ethernet Gadget interface with a static IPv4 address:

- **Watch IP**: `192.168.2.15`
- **Host Subnet**: `192.168.2.0/24`

Configure the USB network interface on your host machine:

```bash
# Identify USB network interface (e.g., usb0, enp0s20f0u...)
ip link

# Assign host IP
sudo ip addr add 192.168.2.14/24 dev usb0
sudo ip link set usb0 up

# Test connectivity
ping 192.168.2.15
```

### Connecting via SSH

Open a remote shell on the watch:

```bash
ssh root@192.168.2.15
```

### Updating Live System Configurations

To deploy updates, bug fixes, or new watch packages directly to the running smartwatch from your host workstation:

#### Option A: Direct NixOS Rebuild over SSH

```bash
nixos-rebuild switch \
  -I nixos-config=./examples/asteroid/configuration.nix \
  --target-host root@192.168.2.15
```

#### Option B: Closure Copy & Instant Activation

Build the new system generation on your powerful host workstation, copy the store paths over USB Ethernet, and switch configurations:

```bash
# 1. Build the updated system closure on host
nix-build examples/asteroid --argstr device fossil-hoki -A build.toplevel

# 2. Copy the store closure to the watch
nix-copy-closure --to root@192.168.2.15 ./result

# 3. Activate the new generation on the watch
ssh root@192.168.2.15 "nix-env -p /nix/var/nix/profiles/system --set $(readlink -f result) && /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
```

If any configuration causes an issue, roll back instantly:

```bash
ssh root@192.168.2.15 "/nix/var/nix/profiles/system/bin/switch-to-configuration boot"
```

---

## Application Suite

The environment includes a rich catalog of touch-optimized smartwatch applications:

- 🌐 **`asteroid-browser`**: Lightweight web browser with integrated virtual keyboard support and wearable quick-links.
- 💬 **`asteroid-telegram`**: Native smartwatch Telegram client with touch-friendly chat lists, message history, voice reply integration, and quick canned responses.
- ⌨️ **`asteroid-virtualkeyboard-rime`**: On-screen touch keyboard featuring integrated [RIME](https://rime.im/) input method engine support and bundled Chinese dictionaries.
- 🎵 **`asteroid-beatfork`**: High-precision metronome and chromatic tuning fork with Tack-inspired tap tempo calculation, accented subdivisions (1/4, 2/4, 3/4, 4/4, 6/8), concentric visual pulse ring, and distinct smartwatch haptics.
- 🗺️ **`asteroid-map`**: Touch GPS map viewer featuring offline tile cache persistence, compass heading orientation, and circular edge controls.
- 🎧 **`asteroid-music`**: Media playback remote controller for phone media players via Bluetooth MPRIS, enhanced with standalone YouTube Music streaming directly on the watch.
- ⏱️ **Core Utilities**: Stopwatch, Countdown Timer, Alarm Clock, Calculator, Weather, Compass, Flashlight, and Heart Rate Monitor.

---

## Architecture & Design

The operating system combines three robust software layers:

```
┌────────────────────────────────────────────────────────┐
│               AsteroidOS Userland Apps                 │
│ (Launcher, Watchfaces, Browser, Telegram, Beatfork, …)  │
├────────────────────────────────────────────────────────┤
│                 Wayland Shell & QML                    │
│    (asteroid-launcher, qml-asteroid, Qt 6, Wayland)    │
├────────────────────────────────────────────────────────┤
│                     NixOS Core                         │
│   (systemd, PipeWire/PulseAudio, BlueZ, NetworkManager)│
├────────────────────────────────────────────────────────┤
│             Hardware Adaptation Layer                  │
│       (Linux Kernel, libhybris / Android HAL, DRM)     │
└────────────────────────────────────────────────────────┘
```

---

## Acknowledgments

- [AsteroidOS Project](https://asteroidos.org/) – for hardware reverse engineering, device drivers, and userland QML designs.
- [Mobile NixOS Project](https://mobile-nixos.github.io/) – for foundational mobile NixOS abstractions.
- [Nixpkgs / NixOS](https://nixos.org/) – for declarative, reproducible operating system foundation.
