{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  qt6,
  dconf,
  glib,
}:

stdenv.mkDerivation rec {
  pname = "mlite";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "mlite";
    rev = "42c3b2102dadfc54a2cc7c87c6e4cfb28437c908";
    hash = "sha256-rtWtDJhSUpamqj61aLr2QTopY9QfighPcMlUxdACTlg=";
  };

  nativeBuildInputs = [
    pkg-config
    qt6.qmake
  ];

  postPatch = ''
    substituteInPlace mlite.pro --replace-fail 'tests' ""
  '';

  buildInputs = [
    qt6.qtbase
    dconf
    glib
  ];

  dontWrapQtApps = true;

  qmakeFlags = [
    "PREFIX=$(out)"
  ];

  installFlags = [
    "INSTALL_ROOT=$(out)"
  ];

  postInstall = ''
    mkdir -p $out/lib $out/include
    if [ -d "$out/usr/include" ]; then
      cp -r $out/usr/include/* $out/include/
      rm -rf $out/usr
    fi
    STORE_LIB=$(find $out/nix/store -name "lib" -type d | head -n 1)
    if [ -n "$STORE_LIB" ] && [ -d "$STORE_LIB" ]; then
      cp -r $STORE_LIB/* $out/lib/
      rm -rf $out/nix
    fi
    if [ -f "$out/lib/pkgconfig/mlite6.pc" ]; then
      sed -i "s|^prefix=.*|prefix=$out|" "$out/lib/pkgconfig/mlite6.pc"
      sed -i "s|^includedir=.*|includedir=$out/include/mlite6|" "$out/lib/pkgconfig/mlite6.pc"
    fi
  '';

  meta = with lib; {
    description = "MeeGo Touch Framework utilities and configuration item classes";
    homepage = "https://github.com/sailfishos/mlite";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
