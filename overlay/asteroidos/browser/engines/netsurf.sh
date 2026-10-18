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

# Wayland display environment and touch scrolling
export GDK_BACKEND="${GDK_BACKEND:-wayland}"
export GDK_SCALE="${ASTEROID_BROWSER_SCALE:-1}"
export GDK_CORE_DEVICE_EVENTS=1
export GTK_OVERLAY_SCROLLING=1

# Auto-provision round-screen user stylesheet if not customized by user
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/netsurf"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/user.css" ] && [ -f "${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/watch-round.css" ]; then
    cp "${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/watch-round.css" "$CONFIG_DIR/user.css"
fi

exec "$NETSURF_EXEC" "$TARGET_URL"
