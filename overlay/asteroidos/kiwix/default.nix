{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  libzim,
  qml-asteroid,
  virtualkeyboard ? null,
  qtvirtualkeyboard ? qt6.qtvirtualkeyboard,
  buildPackages,
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-kiwix";
  version = "2.0.0";

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
    libzim
    qml-asteroid
  ];

  qtWrapperArgs = [
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${qml-asteroid}/lib/qt-6/qml"
    "--set-default"
    "QT_IM_MODULE"
    "qtvirtualkeyboard"
    "--set-default"
    "QT_VIRTUALKEYBOARD_STYLE"
    "watch"
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
    description = "Native lightweight offline Wikipedia and ZIM reader for AsteroidOS powered by libzim with virtual keyboard search";
    homepage = "https://www.kiwix.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "asteroid-kiwix";
  };
})
