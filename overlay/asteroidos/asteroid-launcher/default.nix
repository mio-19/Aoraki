{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "asteroid-launcher";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-launcher";
    rev = "0ba0eb50a68fc6f1019312d511ec3e2fd1b48f31";
    sha256 = "0lrfk1m4kn9z47v0xr7mhgzi5kyahchf43jml7rzxq20limblrmn";
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
    qt6.qtwayland
    qt6.qtsensors
    qt6.qtshadertools
    qml-asteroid
  ];

  meta = with lib; {
    description = "AsteroidOS Wayland compositor and smartwatch home shell";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
