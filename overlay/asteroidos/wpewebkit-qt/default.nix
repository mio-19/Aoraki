# WPE WebKit Qt6 Quick / QML plugin (WPEQt)
# Upstream: https://github.com/nowrep/wpewebkit-qt
# Inspired by WPE WebKit for embedded devices: https://wpewebkit.org/
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  wpewebkit,
  libwpe,
  libwpe-fdo,
  libepoxy,
  mesa,
  glib,
  buildPackages,
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "wpewebkit-qt";
  version = "0.1.0-unstable-2024-05-18";

  src = fetchFromGitHub {
    owner = "nowrep";
    repo = "wpewebkit-qt";
    rev = "4632cb569d6e79c54dd4df17fd9bba297ad76974";
    sha256 = "04c12bacrf5py7rhrzs3hvxj79g7c43wylhrbgkbp5nqirq7m6yr";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  cmakeFlags = [
    "-DUSE_QT6=ON"
  ]
  ++ lib.optionals isCross [
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    wpewebkit
    libwpe
    libwpe-fdo
    libepoxy
    mesa
    glib
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    description = "WPE WebKit QML plugin for Qt6";
    homepage = "https://github.com/nowrep/wpewebkit-qt";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
  };
})
