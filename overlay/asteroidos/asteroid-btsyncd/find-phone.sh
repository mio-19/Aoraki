#!/bin/sh
set -e

DEST="org.asteroidos.btsyncd"
OBJECT="/org/asteroidos/btsyncd/findphone"
INTERFACE="org.asteroidos.btsyncd.FindPhone"

usage() {
    echo "Usage: find-phone [toggle|start|stop|status]"
    exit 1
}

case "$1" in
    ""|toggle)
        busctl call "$DEST" "$OBJECT" "$INTERFACE" toggleRing 2>/dev/null || \
        gdbus call --system --dest "$DEST" --object-path "$OBJECT" --method "$INTERFACE.toggleRing" 2>/dev/null || \
        dbus-send --system --print-reply --dest="$DEST" "$OBJECT" "$INTERFACE.toggleRing"
        ;;
    start|on|ring)
        busctl call "$DEST" "$OBJECT" "$INTERFACE" ringPhone b true 2>/dev/null || \
        gdbus call --system --dest "$DEST" --object-path "$OBJECT" --method "$INTERFACE.ringPhone" true 2>/dev/null || \
        dbus-send --system --print-reply --dest="$DEST" "$OBJECT" "$INTERFACE.ringPhone" boolean:true
        ;;
    stop|off|silence)
        busctl call "$DEST" "$OBJECT" "$INTERFACE" ringPhone b false 2>/dev/null || \
        gdbus call --system --dest "$DEST" --object-path "$OBJECT" --method "$INTERFACE.ringPhone" false 2>/dev/null || \
        dbus-send --system --print-reply --dest="$DEST" "$OBJECT" "$INTERFACE.ringPhone" boolean:false
        ;;
    status)
        busctl call "$DEST" "$OBJECT" "$INTERFACE" isRinging 2>/dev/null || \
        gdbus call --system --dest "$DEST" --object-path "$OBJECT" --method "$INTERFACE.isRinging" 2>/dev/null || \
        dbus-send --system --print-reply --dest="$DEST" "$OBJECT" "$INTERFACE.isRinging"
        ;;
    *)
        usage
        ;;
esac
