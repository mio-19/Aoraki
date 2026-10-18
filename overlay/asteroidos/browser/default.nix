# AsteroidOS smartwatch browser powered by QtWebEngine
# Architecture inspired by AsteroidOS application suite: https://asteroidos.org/
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  virtualkeyboard ? null,
  qtvirtualkeyboard ? qt6.qtvirtualkeyboard,
  buildPackages,
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-browser";
  version = "1.0.0";

  src = ./.;

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  cmakeFlags = lib.optionals isCross [
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwebengine
    qml-asteroid
  ];

  qtWrapperArgs = [
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${qml-asteroid}/lib/qt-6/qml"
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${qt6.qtwebengine}/lib/qt-6/qml"
    "--set-default"
    "QT_IM_MODULE"
    "qtvirtualkeyboard"
    "--set-default"
    "QT_VIRTUALKEYBOARD_STYLE"
    "watch"
    "--set-default"
    "ASTEROID_BROWSER_SHARE"
    "${placeholder "out"}/share/asteroid-browser"
  ]
  ++ lib.optionals (qtvirtualkeyboard != null) [
    "--prefix"
    "QT_PLUGIN_PATH"
    ":"
    "${qtvirtualkeyboard}/lib/qt-6/plugins"
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${qtvirtualkeyboard}/lib/qt-6/qml"
  ]
  ++ lib.optionals (virtualkeyboard != null) [
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${virtualkeyboard}/lib/qt-6/qml"
    "--set-default"
    "QT_VIRTUALKEYBOARD_LAYOUT_PATH"
    "${virtualkeyboard}/share/qtvirtualkeyboard/layouts"
    "--set-default"
    "RIME_SHARED_DATA_DIR"
    "${virtualkeyboard}/share/rime-data"
  ];

  meta = with lib; {
    description = "Smartwatch web browser interface for AsteroidOS powered by QtWebEngine with virtual keyboard integration";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "asteroid-browser";
  };
})
