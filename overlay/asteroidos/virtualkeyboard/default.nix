{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  librime,
  rime-data,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-virtualkeyboard";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-virtualkeyboard";
    rev = "666743fc42eaa02b9f82155ff3aff3a40e0d45ac";
    sha256 = "0yw1xq315p7q7illjpq92cs0060lrw94bfk8ywc7fbrr1gmkmvjf";
  };

  patches = [
    ./0001-add-rime-plugin-and-layouts.patch
  ];

  postPatch = ''
    cp ${./rimeinputmethod.cpp} rimeinputmethod.cpp
    cp ${./rimeinputmethod.h} rimeinputmethod.h
    mkdir -p layouts
    cp -r ${./layouts}/* layouts/
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
    buildPackages.librime
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtvirtualkeyboard
    librime
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_DATADIR=share"
  ]
  ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  ];

  # Pre-deploy common Chinese schemas (Pinyin, Shuangpin, Wubi, Cangjie, Stroke, Bopomofo, Jyutping)
  # Upstream: https://github.com/rime/librime
  postInstall = ''
    mkdir -p $out/share/rime-data/build
    cp -r ${rime-data}/share/rime-data/* $out/share/rime-data/

    # Run rime_deployer on host buildPlatform to compile binary tables
    mkdir -p build-deploy/user build-deploy/staging
    ${buildPackages.librime}/bin/rime_deployer --add-schema \
      luna_pinyin double_pinyin wubi86 cangjie5 stroke bopomofo jyutping \
      build-deploy/user $out/share/rime-data

    ${buildPackages.librime}/bin/rime_deployer --build \
      build-deploy/user $out/share/rime-data build-deploy/staging || true

    cp -n build-deploy/staging/* $out/share/rime-data/build/ 2>/dev/null || true
    cp -n build-deploy/staging/* $out/share/rime-data/ 2>/dev/null || true
  '';

  meta = with lib; {
    description = "AsteroidOS on-screen virtual keyboard with watch style, layouts, and integrated RIME input method engine";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
})
