#!/bin/sh
# AsteroidOS Browser Engine Driver: Servo
# Parallel web engine written in Rust
# Upstream: https://servo.org/

set -e

TARGET_URL="$1"
if [ -z "$TARGET_URL" ]; then
    TARGET_URL="file://${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/portal.html"
fi

SERVO_EXEC="${SERVO_BIN:-servo}"

# Wayland display environment
export WINIT_UNIX_BACKEND=wayland

exec "$SERVO_EXEC" \
    --output-scale="${ASTEROID_BROWSER_SCALE:-0.75}" \
    "$TARGET_URL"
