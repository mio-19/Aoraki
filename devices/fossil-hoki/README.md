# Fossil Gen 6 (`fossil-hoki`) Device Notes

The **Fossil Gen 6** (codename `hoki`) is the primary reference smartwatch platform for NixOS for Smartwatches. It features Qualcomm Snapdragon Wear 4100+ silicon, a 416×416 round AMOLED display, and a digital rotating crown.

---

## Hardware Specifications

| Component | Specification | Notes |
| :--- | :--- | :--- |
| **SoC** | Qualcomm Snapdragon Wear 4100+ (SDA429W) | 4× ARM Cortex-A7 @ 1.95 GHz, Adreno 504 GPU |
| **Memory** | 1 GB LPDDR3 | Shared system RAM |
| **Storage** | 8 GB eMMC 5.1 | Partitioned for A/B boot and large `userdata` |
| **Display** | 1.28″ Round AMOLED (416×416, ~326 ppi) | 60 Hz refresh, Always-On Display (AOD) ambient mode |
| **Touch** | Capacitive multi-touch | Handled via `evdevtouch` Qt input plugin |
| **Controls** | Digital rotating crown + 2 hardware push-buttons | Crown mapped to rotary encoder input |
| **Haptics** | Linear Resonant Actuator (LRA) | Controlled via `ff-memless` force-feedback driver |
| **Wireless** | Wi-Fi 802.11 b/g/n + Bluetooth 5.0 LE / BR/EDR | BlueZ dual-mode configuration (`ControllerMode = dual`) |
| **Sensors** | Heart rate (PPG), Accelerometer, Gyroscope, Compass, Off-body | Calibrated via `/persist` partition |

---

## Partition Architecture & Mounts

The Fossil Gen 6 utilizes Qualcomm A/B partition architecture on its internal eMMC:

| Partition / Partlabel | Mount Point | Filesystem | Mount Flags | Description |
| :--- | :--- | :--- | :--- | :--- |
| `boot_a` / `boot_b` | — | Android Boot v0 | — | Linux 4.14 kernel with appended `sda429-hoki.dtb` + mobile-nixos stage-1 initrd |
| `userdata` | `/` | ext4 | rw | Target for `system.img` (`LABEL=NIXOS_SYSTEM`). Provides ~4–5 GB space for Nix store. |
| `persist` | `/persist` | ext4 | nofail | Optical sensor calibration, board serials, and battery fuel-gauge profiles |
| `modem` | `/vendor/firmware_mnt` | vfat | ro, nofail | Qualcomm Hexagon DSP firmware and Wi-Fi/GNSS binaries |
| `bluetooth` | `/vendor/bt_firmware` | vfat | ro, nofail | Broadcom / Qualcomm Bluetooth controller firmware |

> [!IMPORTANT]
> The `/persist`, `/vendor/firmware_mnt`, and `/vendor/bt_firmware` mounts use `nofail` so that unformatted partitions or read-only stages do not block booting into emergency shell.

---

## Fastboot Key Combinations

- **Enter Fastboot Mode from Power-Off**: Place watch on charging puck, then hold down the **middle crown button + bottom push-button** simultaneously until the fastboot bootloader screen appears.
- **Force Reboot / Rescue from Hang**: If the watch hangs during kernel or early userland experimentation, hold down the **middle crown button + bottom push-button** for ~10 seconds to force a hardware reset directly back into the fastboot bootloader.
- **Enter Fastboot from ADB**:
  ```bash
  adb reboot bootloader
  ```

---

## Flashing Instructions

```bash
# 1. Verify fastboot communication:
fastboot devices

# 2. Flash kernel and stage-1 initramfs to both A/B slots:
fastboot flash --slot=all boot result/boot.img
# (Alternatively, run the generated ./result/flash-critical.sh)

# 3. Flash root filesystem into userdata (recommended for full eMMC space):
fastboot flash userdata result/system.img

# 4. Optional: clear stale Android cache if migrating from Wear OS:
fastboot format cache

# 5. Reboot into NixOS:
fastboot reboot
```

---

## Compositor & Display Architecture

- **Compositor**: `asteroid-launcher` runs as a systemd user service under user `ceres`:
  ```bash
  systemctl --user status asteroid-launcher
  ```
- **Platform Plugin**: Qt 6 uses `hwcomposer` (`QT_QPA_PLATFORM=hwcomposer`, `EGL_PLATFORM=hwcomposer`) to talk to the Qualcomm Android HAL (`libhybris`).
- **Touch Input**: Launched with `-plugin evdevtouch --systemd`.
- **Rotary Crown**: Handled as evdev axis/key events in `asteroid-launcher`.

---

## Debugging & Remote Shell Access

When booted, the watch exposes a USB CDC Ethernet interface (`192.168.2.15`):

```bash
# Configure host network:
sudo ip addr add 192.168.2.14/24 dev usb0
sudo ip link set usb0 up

# SSH to the watch:
ssh root@192.168.2.15

# Inspect compositor logs:
journalctl --user -u asteroid-launcher -f

# Inspect kernel dmesg:
dmesg | grep -iE "msm|drm|bluetooth|wlan|touch"
```
