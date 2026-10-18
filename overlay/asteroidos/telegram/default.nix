{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-telegram";
  version = "1.0.0";

  src = ./.;

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  cmakeFlags = lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qml-asteroid
  ];

  qtWrapperArgs = [
    "--prefix"
    "QML2_IMPORT_PATH"
    ":"
    "${qml-asteroid}/lib/qt-6/qml"
  ];

  meta = with lib; {
    description = "Smartwatch Telegram client for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    mainProgram = "asteroid-telegram";
    platforms = platforms.linux;
  };
})
