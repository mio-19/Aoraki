#!/bin/sh
# AsteroidOS Browser Engine Driver: WebKit
# Embedded WebKit engine (WebKitGTK / WPE)
# Upstream: https://webkit.org/

set -e

TARGET_URL="$1"
if [ -z "$TARGET_URL" ]; then
    TARGET_URL="file://${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/portal.html"
fi

WEBKIT_EXEC="${WEBKIT_BIN:-MiniBrowser}"
if ! command -v "$WEBKIT_EXEC" >/dev/null 2>&1; then
    if command -v cog >/dev/null 2>&1; then
        WEBKIT_EXEC="cog"
    elif [ -x /run/current-system/sw/libexec/webkit2gtk-4.1/MiniBrowser ]; then
        WEBKIT_EXEC="/run/current-system/sw/libexec/webkit2gtk-4.1/MiniBrowser"
    elif [ -x /run/current-system/sw/libexec/webkitgtk-6.0/MiniBrowser ]; then
        WEBKIT_EXEC="/run/current-system/sw/libexec/webkitgtk-6.0/MiniBrowser"
    fi
fi

# Wayland display environment
export GDK_BACKEND="${GDK_BACKEND:-wayland}"
export WEBKIT_FORCE_SANDBOX=0

exec "$WEBKIT_EXEC" "$TARGET_URL"
