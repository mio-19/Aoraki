{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  qt6,
}:

stdenv.mkDerivation rec {
  pname = "amber-mpris";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "amber-mpris";
    rev = "0dc2c15104a13c16f3028cb9e73f1e4dc886f4d0";
    hash = "sha256-kOjzaF6Xu1D06V8Dq9i0mUXwROH0rXTNC2zVnbiYUHI=";
  };

  nativeBuildInputs = [
    pkg-config
    qt6.qmake
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
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
    if [ -f "$out/lib/pkgconfig/ambermpris6.pc" ]; then
      sed -i "s|^prefix=.*|prefix=$out|" "$out/lib/pkgconfig/ambermpris6.pc"
      sed -i "s|^includedir=.*|includedir=$out/include/AmberMpris|" "$out/lib/pkgconfig/ambermpris6.pc"
    fi
  '';

  meta = with lib; {
    description = "Qt and QML MPRIS interface and adaptor";
    homepage = "https://github.com/sailfishos/amber-mpris";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
