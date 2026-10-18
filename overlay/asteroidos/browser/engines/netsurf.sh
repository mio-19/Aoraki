#!/bin/sh
# AsteroidOS Browser Engine Driver: NetSurf
# Ultra-lightweight browser engine (~30MB RAM) ideal for wearables
# Upstream: https://www.netsurf-browser.org/

set -e

TARGET_URL="$1"
if [ -z "$TARGET_URL" ]; then
    TARGET_URL="file://${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/portal.html"
fi

NETSURF_EXEC="${NETSURF_BIN:-netsurf-gtk3}"
if ! command -v "$NETSURF_EXEC" >/dev/null 2>&1; then
    if command -v netsurf-gtk >/dev/null 2>&1; then
        NETSURF_EXEC="netsurf-gtk"
    elif command -v netsurf >/dev/null 2>&1; then
        NETSURF_EXEC="netsurf"
    fi
fi

# Wayland display environment
export GDK_BACKEND="${GDK_BACKEND:-wayland}"
export GDK_SCALE="${ASTEROID_BROWSER_SCALE:-1}"

exec "$NETSURF_EXEC" "$TARGET_URL"
