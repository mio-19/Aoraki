# Known Issues & Bug Tracker

This document tracks known issues, edge cases, root cause analyses, and workarounds for NixOS on Smartwatches.

---

## 1. Resilient Flasher / Recovery `dd`: `Invalid argument` at Chunk 129 (2 GiB Boundary)

### Symptoms
When using `bin/resilient-flash` over ADB recovery to flash a system image to `/dev/block/bootdevice/by-name/userdata`, flashing succeeds up to Chunk 128 (87%), then repeatedly fails at Chunk 129 (88%):

```text
[ 88%] Chunk 129/146 (16.0 MB): Writing...dd: /dev/block/bootdevice/by-name/userdata: Invalid argument
 FAILED: dd write failed: dd: /dev/block/bootdevice/by-name/userdata: Invalid argument
```

### Technical Root Cause Analysis
Chunk 129 corresponds to index 128 with default 16 MB chunks:
$$\text{Offset} = 128 \times 16\text{ MB} = 2048\text{ MB} = 2{,}147{,}483{,}648\text{ bytes (exactly } 2\text{ GiB)}$$

$2{,}147{,}483{,}648$ ($0\times80000000$) is the boundary where a signed 32-bit integer overflows to $-2{,}147{,}483{,}648$ (`INT32_MIN`). On Linux systems, this produces an `EINVAL` (`Invalid argument`) error from two distinct mechanisms:

1. **Signed 32-bit Offset Overflow in Recovery `dd` / `lseek`**:
   The `dd` command executes on the smartwatch inside the 32-bit ARM (`armv7l`) recovery environment:
   ```bash
   dd of=/dev/block/... bs=1048576 seek=2048
   ```
   In 32-bit toolbox/toybox builds lacking full 64-bit `off_t` math, evaluating `seek * bs` overflows to a negative integer (`-2147483648`). Calling `lseek(fd, -2147483648, SEEK_SET)` is rejected by the Linux kernel with `-EINVAL` (`Invalid argument`).

2. **Block Device End-of-Partition Limit**:
   On many smartwatch partition tables (e.g. 4 GB eMMC devices, or 8 GB devices with partitioned system/vendor/userdata), the `userdata` partition capacity is fixed at $2.0\text{ GB}$ ($2048\text{ MB}$).
   In the Linux kernel block layer (`block/fops.c:fixed_size_llseek`):
   ```c
   if (offset < 0 || offset > size)
       return -EINVAL;
   ```
   Seeking beyond the physical end of a raw block device returns `EINVAL` (`Invalid argument`).

### Why Did Earlier Flashes Succeed?
Earlier builds succeeded not because of the host OS (Linux vs macOS), but because of the **image closure size**:
- Earlier builds with lightweight components produced an uncompressed filesystem of **$1.02\text{ GB}$ (65 chunks)**. Flashing completed at Chunk 65 without ever reaching the $2\text{ GiB}$ ($2048\text{ MB}$) threshold.
- Including desktop WebKit (`webkitgtk-6.0`), GTK4, and GStreamer expanded the uncompressed rootfs to **$2.45\text{ GB}$ (146 chunks)**. The flasher crossed Chunk 129 ($2048\text{ MB}$) for the first time, exposing the 2 GiB limit.

### Diagnostics & Workarounds

1. **Verify Partition Capacity on Watch**:
   With the watch connected in recovery mode, query the partition size in bytes:
   ```bash
   adb shell "blockdev --getsize64 /dev/block/bootdevice/by-name/userdata"
   # or
   adb shell "cat /proc/partitions"
   ```
   If the reported size is $2{,}147{,}483{,}648$ ($2.0\text{ GB}$) or smaller, the uncompressed image exceeds the partition size.

2. **Fastboot Native Flashing (Bypasses Recovery `dd`)**:
   When flashing images over 2 GB on devices with large userdata partitions, use native fastboot:
   ```bash
   fastboot flash userdata system.img
   ```
   Fastboot transfers Android sparse images (`simg`) directly and does not depend on 32-bit recovery `dd` seek arithmetic.

3. **Closure Size Budgeting for Smartwatches**:
   Keep smartwatch image closures under $1.8\text{ GB}$ uncompressed so that images safely fit on fixed $2.0\text{ GB}$ smartwatch partitions.
