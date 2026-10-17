{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  extra-cmake-modules,
  pkg-config,
  qt5,
}:

stdenv.mkDerivation rec {
  pname = "qml-asteroid";
  version = "2.1";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "qml-asteroid";
    rev = version;
    sha256 = "05d5s9drc4mf21527jlzdzd466wiwhgyi89xrn5acphc31fmzxvh";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtdeclarative
    qt5.qtsvg
    qt5.qtquickcontrols
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
