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
if ! command -v "$LADYBIRD_EXEC" >/dev/null 2>&1; then
    if [ -x "/run/current-system/sw/bin/Ladybird" ]; then
        LADYBIRD_EXEC="/run/current-system/sw/bin/Ladybird"
    fi
fi

# Wayland & Qt watch environment
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_SCALE_FACTOR="${ASTEROID_BROWSER_SCALE:-0.75}"
export QT_IM_MODULE="${QT_IM_MODULE:-qtvirtualkeyboard}"
export QT_VIRTUALKEYBOARD_STYLE="${QT_VIRTUALKEYBOARD_STYLE:-watch}"

# Auto-provision Ladybird.ini for smartwatch screen geometry
LADYBIRD_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Ladybird"
mkdir -p "$LADYBIRD_CONFIG_DIR"
if [ ! -f "$LADYBIRD_CONFIG_DIR/Ladybird.ini" ]; then
    cat <<'EOF' > "$LADYBIRD_CONFIG_DIR/Ladybird.ini"
[General]
is_maximized=true
last_size=@Size(416 416)
last_position=@Point(0 0)
EOF
fi

# Launch Ladybird with smartwatch flags
exec "$LADYBIRD_EXEC" \
    --disable-sandbox \
    --disable-scrollbar-painting \
    --force-cpu-painting \
    "$TARGET_URL"
