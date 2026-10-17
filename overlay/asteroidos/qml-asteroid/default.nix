{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "qml-asteroid";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "qml-asteroid";
    rev = "c1905485d4aa22f964273e93a62ef23c27a7754b";
    sha256 = "14l43mnff8a7v1dw1d066i0nvswxmj1la3k6a0mxkyzxhykw68iq";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6.qtdeclarative
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtshadertools
    qt6.qtwayland
  ];

  cmakeFlags = [
    "-DWITH_ASTEROIDAPP=OFF"
    "-DWITH_CMAKE_MODULES=ON"
  ];

  meta = with lib; {
    description = "QML components, styles, and controls for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
  };
}
