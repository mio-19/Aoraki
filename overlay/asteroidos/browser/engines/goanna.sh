#!/bin/sh
# AsteroidOS Browser Engine Driver: Goanna
# Lightweight Gecko fork engine for resource-constrained systems
# Upstream: https://repo.palemoon.org/MoonchildProductions/UXP

set -e

TARGET_URL="$1"
if [ -z "$TARGET_URL" ]; then
    TARGET_URL="file://${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/portal.html"
fi

GOANNA_EXEC="${GOANNA_BIN:-goanna}"
if ! command -v "$GOANNA_EXEC" >/dev/null 2>&1; then
    if command -v palemoon >/dev/null 2>&1; then
        GOANNA_EXEC="palemoon"
    elif command -v basilisk >/dev/null 2>&1; then
        GOANNA_EXEC="basilisk"
    fi
fi

# Wayland display environment
export MOZ_ENABLE_WAYLAND=1

exec "$GOANNA_EXEC" "$TARGET_URL"
