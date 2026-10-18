{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
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
