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
  buildPackages,
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-btsyncd";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-btsyncd";
    rev = "e14fbcd9a157f0988204e874b03f6f800f89d645";
    sha256 = "15vpd3y817gz8j1d7f56k5g1y3747grsjqc5z7b896n7rs2p8ijc";
  };

  strictDeps = true;

  # AsteroidOS Bluetooth synchronization daemon
  # Upstream repository: https://github.com/AsteroidOS/asteroid-btsyncd
  # Companion phone app protocol (Gadgetbridge): https://codeberg.org/Freeyourgadget/Gadgetbridge
  patches = [
    # Adds find-phone D-Bus command and synchronization packet support for Gadgetbridge
    ./find-phone.patch
    # Generic App Bridge GATT service and D-Bus interface for remote camera and sensor sync
    ./app-bridge.patch
  ];

  postPatch = ''
    cp ${./appbridgeservice.h} src/appbridgeservice.h
    cp ${./appbridgeservice.cpp} src/appbridgeservice.cpp
  '';

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6.wrapQtAppsHook
  ];

  cmakeFlags = [
    "-DECM_DIR=${kdePackages.extra-cmake-modules}/share/ECM/cmake"
  ]
  ++ lib.optionals isCross [
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
    "-DQt6LinguistTools_DIR=${buildPackages.qt6.qttools}/lib/cmake/Qt6LinguistTools"
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
    install -Dm755 ${./find-phone.sh} $out/bin/find-phone
    install -Dm755 ${./camera-shutter.sh} $out/bin/camera-shutter
    install -Dm644 ${./org.asteroidos.btsyncd.conf} $out/share/dbus-1/system.d/org.asteroidos.btsyncd.conf
  '';

  meta = with lib; {
    description = "Bluetooth Low Energy synchronization daemon for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
})
