#!/bin/sh
# AsteroidOS Browser Engine Driver: Ladybird
# Upstream: https://github.com/LadybirdBrowser/ladybird

set -e

# Target URL or default watch portal
TARGET_URL="$1"
if [ -z "$TARGET_URL" ]; then
    TARGET_URL="file://${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/portal.html"
fi

# Locate Ladybird binary
LADYBIRD_EXEC="${LADYBIRD_BIN:-Ladybird}"

# Wayland & Qt watch environment
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_SCALE_FACTOR="${ASTEROID_BROWSER_SCALE:-0.75}"
export QT_IM_MODULE="${QT_IM_MODULE:-qtvirtualkeyboard}"
export QT_VIRTUALKEYBOARD_STYLE="${QT_VIRTUALKEYBOARD_STYLE:-watch}"

# Locate watch stylesheet
THEME_QSS="${WATCH_THEME_QSS:-${ASTEROID_BROWSER_SHARE:-/usr/share/asteroid-browser}/watch-theme.qss}"

# Launch Ladybird with smartwatch flags
exec "$LADYBIRD_EXEC" \
    --disable-scrollbar-painting \
    --force-cpu-painting \
    -stylesheet "$THEME_QSS" \
    "$TARGET_URL"
