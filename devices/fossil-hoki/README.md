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
| `userdata` | `/` | Btrfs (zstd:3) | rw | Target for `system.img` (`LABEL=NIXOS_SYSTEM`). Transparently compressed to maximize Nix store space. |
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

### Method 1: Fastboot with Native Sparse Image (Recommended)

The generated `result/system.img` is automatically formatted as a native Android sparse filesystem image (`img2simg`). This avoids fastboot client-side chunking errors (`Invalid sparse file format at header magic` / `Error reading sparse file`) and skips empty blocks to speed up transfers over USB pogo pins:

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

### Method 2: Alternative Flashing via TWRP Recovery (Untested / Community Method)

> [!WARNING]
> **Experimental / Untested**: Flashing via TWRP recovery on `fossil-hoki` is a community-developed workaround and is currently **untested** in our primary pipeline. Use the native sparse fastboot method (Method 1) whenever possible.

The magnetic charging cradle on the Fossil Gen 6 can be physically sensitive; slight shifts during multi-minute fastboot writes can reset the USB interface (`Write to device failed`, `Status read failed (No such device)`).

An alternative community method is to temporarily boot **TWRP Recovery for Fossil Gen 6 (hoki)** (developed by Malvik on [XDA Forums](https://xdaforums.com/t/twrp-twrp-for-fossil-gen-6-aka-hoki.4474863/)):

1. **Boot TWRP temporarily via fastboot** (does not overwrite stock recovery):
   ```bash
   fastboot boot twrp_hoki.img
   ```

2. **Wait for TWRP to start ADB**:
   Verify the watch is recognized in recovery mode:
   ```bash
   adb devices
   ```

3. **Stream the rootfs image directly to the eMMC partition**:
   Because `/tmp` on the watch is a RAM disk (limited to ~1 GB total memory), do NOT push the image to `/tmp`. Unsparse the image on your host machine and stream it via `adb exec-in` (disables terminal PTY line translation so binary data is not corrupted) using numeric block size:
   ```bash
   # 1. Unsparse on host machine:
   simg2img result/system.img /tmp/system_raw.img

   # 2. Stream directly into userdata partition:
   adb exec-in "dd of=/dev/block/bootdevice/by-name/userdata bs=1048576" < /tmp/system_raw.img

   # 3. Clean up host temporary raw image:
   rm -f /tmp/system_raw.img
   ```

4. **Flash kernel and stage-1 initrd to both boot slots**:
   ```bash
   adb exec-in "dd of=/dev/block/bootdevice/by-name/boot_a bs=1048576" < result/boot.img
   adb exec-in "dd of=/dev/block/bootdevice/by-name/boot_b bs=1048576" < result/boot.img
   ```

5. **Wipe stale cache and reboot**:
   ```bash
   adb shell "mke2fs -t ext4 /dev/block/bootdevice/by-name/cache" || adb shell "make_ext4fs /dev/block/bootdevice/by-name/cache"
   adb reboot
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

---

## Kiwix Offline Wikipedia & Reference Reader

The watch environment includes Kiwix (`asteroid.apps.kiwix`) paired with an ultra-lightweight NetSurf browser backend. To load offline encyclopedias or books:

1. Download `.zim` files from [library.kiwix.org](https://library.kiwix.org/) (e.g. *Wikipedia Simple English*, *Wiktionary*, or *Project Gutenberg*).
2. Transfer the `.zim` file to the watch over USB or SSH:
   ```bash
   # Via ADB:
   adb push wikipedia_en_simple_all_nopic_2024.zim /var/lib/kiwix/

   # Via SSH over USB networking:
   scp wikipedia_en_simple_all_nopic_2024.zim root@192.168.2.15:/var/lib/kiwix/
   ```
3. Open **Kiwix** from the AsteroidOS app drawer or tap **Kiwix (Offline)** on the browser home portal. Articles and full-text search are instantly accessible directly on the wrist.

