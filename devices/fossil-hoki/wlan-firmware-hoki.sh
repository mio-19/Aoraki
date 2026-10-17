#!/bin/sh
# SPDX-License-Identifier: MIT
# Fossil Gen 6 (hoki) Wi-Fi WCNSS firmware extraction and initialization.
# Symlinks stock vendor WCNSS calibration data, triggers WCNSS powerup,
# and loads the WLAN driver module.

mkdir -p /lib/firmware/wlan/prima

for f in WCNSS_qcom_cfg.ini WCNSS_qcom_wlan_nv.bin WCNSS_wlan_dictionary.dat; do
	if [ -e "/vendor/firmware/wlan/prima/$f" ] && [ ! -e "/lib/firmware/wlan/prima/$f" ]; then
		ln -sf "/vendor/firmware/wlan/prima/$f" "/lib/firmware/wlan/prima/$f"
	fi
done

# Opening /dev/wcnss_wlan powers on the WCNSS subsystem
echo 1 > /dev/wcnss_wlan 2>/dev/null || true

modprobe wlan 2>/dev/null || true
exit 0
