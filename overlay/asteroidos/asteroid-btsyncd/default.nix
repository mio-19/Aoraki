{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  systemd,
  qt6,
  qml-asteroid,
  amber-mpris,
  mlite,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "asteroid-btsyncd";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-btsyncd";
    rev = "e14fbcd9a157f0988204e874b03f6f800f89d645";
    sha256 = "15vpd3y817gz8j1d7f56k5g1y3747grsjqc5z7b896n7rs2p8ijc";
  };

  # AsteroidOS Bluetooth synchronization daemon
  # Upstream repository: https://github.com/AsteroidOS/asteroid-btsyncd
  # Companion phone app protocol (Gadgetbridge): https://codeberg.org/Freeyourgadget/Gadgetbridge
  patches = [
    # Adds find-phone D-Bus command and synchronization packet support for Gadgetbridge
    ./find-phone.patch
  ];

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6.qtdeclarative
    qt6.qttools
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    systemd
    qt6.qtbase
    qt6.qtdeclarative
    qml-asteroid
    amber-mpris
    mlite
  ];

  postInstall = ''
        mkdir -p $out/bin
        cat <<'EOF' > $out/bin/find-phone
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
    EOF
        chmod +x $out/bin/find-phone
  '';

  meta = with lib; {
    description = "Bluetooth Low Energy synchronization daemon for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
