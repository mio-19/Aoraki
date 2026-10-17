#!/bin/sh
# SPDX-License-Identifier: MIT
# Fossil Gen 6 (hoki) ALSA mixer and TFA98xx amplifier configuration.
# Polls for ALSA card 0, extracts amplifier DSP firmware container if needed,
# and configures the mixer routing after user session initialization.

i=0
while [ $i -lt 60 ]; do
	if [ -e /proc/asound/card0 ]; then
		sleep 0.5
		break
	fi
	i=$((i+1))
	sleep 0.5
done

if [ ! -e /proc/asound/card0 ]; then
	echo "audio-mixer-fix-hoki: TIMED OUT waiting for card 0" >&2
	exit 1
fi

mkdir -p /lib/firmware
if [ -e /system/etc/firmware/tfa98xx.cnt ] && [ ! -e /lib/firmware/tfa98xx.cnt ]; then
	cp /system/etc/firmware/tfa98xx.cnt /lib/firmware/tfa98xx.cnt
fi

# Load codec modules in dependency order if modular
modprobe audio_analog_cdc 2>/dev/null || true
modprobe audio_digital_cdc 2>/dev/null || true
modprobe audio_machine 2>/dev/null || true

# Wait for pulseaudio / user sound daemon under ceres (UID 1000)
j=0
while [ $j -lt 40 ]; do
	if su ceres -c 'systemctl --user is-active pulseaudio.service' 2>/dev/null | grep -q '^active$'; then
		break
	fi
	j=$((j+1))
	sleep 0.5
done

# Settle buffer to ensure device probing doesn't clobber mixer controls
sleep 5

# numid=348: QUAT_MI2S_RX -> MultiMedia1 (speaker playback route)
amixer -c 0 cset numid=348 1,1 2>/dev/null || true
# numid=1422: MultiMedia1 Mixer TERT_MI2S_TX (real mic capture backend)
amixer -c 0 cset numid=1422 1,1 2>/dev/null || true
# numid=83: DEC1 MUX -> DMIC1 (select digital mic)
amixer -c 0 cset numid=83 DMIC1 2>/dev/null || true

exit 0
