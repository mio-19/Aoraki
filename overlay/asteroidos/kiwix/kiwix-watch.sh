#!/bin/sh
# Kiwix Offline Reader Smartwatch Launcher
# Launches kiwix-serve for local .zim archives and opens the watch browser interface
# Reference: https://github.com/kiwix/kiwix-desktop & https://github.com/kiwix/kiwix-tools

set -e

PORT="${KIWIX_PORT:-8080}"
ADDR="127.0.0.1"
SHARE_DIR="${KIWIX_WATCH_SHARE:-@out@/share/kiwix-watch}"
SYSTEM_ZIM_DIR="/var/lib/kiwix"
USER_ZIM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kiwix"

mkdir -p "$USER_ZIM_DIR" 2>/dev/null || true

# Gather available .zim files
ZIM_FILES=""
for f in "$SYSTEM_ZIM_DIR"/*.zim "$USER_ZIM_DIR"/*.zim; do
    if [ -f "$f" ]; then
        ZIM_FILES="$ZIM_FILES \"$f\""
    fi
done

if [ -z "$ZIM_FILES" ]; then
    # No archives found: display watch-optimized welcome & setup guide
    exec asteroid-browser "file://${SHARE_DIR}/welcome.html"
fi

# Check if kiwix-serve is already running on target port
SERVER_RUNNING=0
if command -v pgrep >/dev/null 2>&1; then
    if pgrep -x kiwix-serve >/dev/null 2>&1; then
        SERVER_RUNNING=1
    fi
fi

if [ "$SERVER_RUNNING" -eq 0 ]; then
    # Start kiwix-serve daemon in background
    # shellcheck disable=SC2086
    eval kiwix-serve --daemon --port="$PORT" --address="$ADDR" --nodatealiases $ZIM_FILES
    sleep 0.5
fi

exec asteroid-browser "http://${ADDR}:${PORT}/"
