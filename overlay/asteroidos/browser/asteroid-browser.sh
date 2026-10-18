#!/bin/sh
# AsteroidOS Smartwatch Web Browser Shell
# Abstraction interface supporting pluggable rendering backends (e.g. Ladybird)

set -e

SHARE_DIR="${ASTEROID_BROWSER_SHARE:-@out@/share/asteroid-browser}"
ENGINES_DIR="${SHARE_DIR}/engines"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/asteroid-browser/engine.conf"
SYSTEM_CONFIG="/etc/asteroid-browser/engine.conf"

# Defaults
DEFAULT_ENGINE="@defaultEngine@"
[ -z "$DEFAULT_ENGINE" ] && DEFAULT_ENGINE="netsurf"
ENGINE="$DEFAULT_ENGINE"
SCALE="0.75"
URL=""

# Read configuration file if present
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
elif [ -f "$SYSTEM_CONFIG" ]; then
    . "$SYSTEM_CONFIG"
fi

# Parse CLI options
while [ "$#" -gt 0 ]; do
    case "$1" in
        --engine=*)
            ENGINE="${1#*=}"
            shift
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        --scale=*)
            SCALE="${1#*=}"
            shift
            ;;
        --list-engines)
            echo "Available AsteroidOS browser engines in ${ENGINES_DIR}:"
            for eng in "${ENGINES_DIR}"/*.sh; do
                [ -f "$eng" ] && basename "$eng" .sh
            done
            exit 0
            ;;
        --help|-h)
            echo "Usage: asteroid-browser [OPTIONS] [URL]"
            echo "AsteroidOS Smartwatch Web Browser with pluggable engine support"
            echo ""
            echo "Options:"
            echo "  -e, --engine <name>   Select browser engine (default: ${DEFAULT_ENGINE})"
            echo "  --scale <factor>      UI scale factor for watch display (default: 0.75)"
            echo "  --list-engines        List available rendering engines"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

export ASTEROID_BROWSER_SHARE="$SHARE_DIR"
export ASTEROID_BROWSER_SCALE="$SCALE"
export WATCH_THEME_QSS="${SHARE_DIR}/watch-theme.qss"

# AsteroidOS Virtual Keyboard environment for watch displays
export QT_IM_MODULE="${QT_IM_MODULE:-qtvirtualkeyboard}"
export QT_VIRTUALKEYBOARD_STYLE="${QT_VIRTUALKEYBOARD_STYLE:-watch}"

ENGINE_SCRIPT="${ENGINES_DIR}/${ENGINE}.sh"

if [ ! -f "$ENGINE_SCRIPT" ]; then
    echo "Error: Unknown or missing browser engine '${ENGINE}'" >&2
    echo "Check available engines with 'asteroid-browser --list-engines'" >&2
    exit 1
fi

exec /bin/sh "$ENGINE_SCRIPT" "$URL"
