{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  mlite,
  mce-dev,
  mce-qt6,
  ngf-qt6,
  usb-moded-qt6,
  keepalive,
  timed-qt6,
  dbus,
  dbus-glib,
  systemd,
  kdePackages,
  buildPackages,
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-launcher";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-launcher";
    rev = "0ba0eb50a68fc6f1019312d511ec3e2fd1b48f31";
    sha256 = "0lrfk1m4kn9z47v0xr7mhgzi5kyahchf43jml7rzxq20limblrmn";
  };

  strictDeps = true;

  # AsteroidOS wayland compositor & shell
  # Upstream repository: https://github.com/AsteroidOS/asteroid-launcher
  patches = [
    # QuickPanel quick-toggle button to trigger the find-phone alarm on the companion phone
    ./find-phone.patch
    # Visible skip button for first-time tutorial and initial setup guide
    ./skip-firstrun.patch
  ];

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
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    qt6.qtsensors
    qt6.qtshadertools
    qml-asteroid
    mlite
    mce-dev
    mce-qt6
    ngf-qt6
    usb-moded-qt6
    keepalive
    timed-qt6
    dbus
    dbus-glib
    systemd
  ];

  meta = with lib; {
    description = "AsteroidOS Wayland compositor and smartwatch home shell";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    mainProgram = "asteroid-launcher";
    platforms = platforms.linux;
  };
})
