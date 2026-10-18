{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  librime,
  rime-data,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-virtualkeyboard-rime";
  version = "1.0.0";

  src = ./.;

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
    description = "Rime input method engine plugin and common Chinese schemas for smartwatch onscreen keyboard";
    homepage = "https://rime.im";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
})
