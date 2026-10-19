#!/bin/sh
set -e

DEST="org.asteroidos.btsyncd"
OBJECT="/org/asteroidos/btsyncd/appbridge"
INTERFACE="org.asteroidos.btsyncd.AppBridge"
ACTION="${1:-capture}"

busctl call "$DEST" "$OBJECT" "$INTERFACE" sendMessage sss "org.asteroidos.camera" "$ACTION" "" 2>/dev/null || \
gdbus call --system --dest "$DEST" --object-path "$OBJECT" --method "$INTERFACE.sendMessage" "org.asteroidos.camera" "$ACTION" "" 2>/dev/null || \
dbus-send --system --print-reply --dest="$DEST" "$OBJECT" "$INTERFACE.sendMessage" string:"org.asteroidos.camera" string:"$ACTION" string:""
