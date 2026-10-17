{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  extra-cmake-modules,
  pkg-config,
  qt5,
  qml-asteroid,
}:

stdenv.mkDerivation rec {
  pname = "asteroid-launcher";
  version = "2.1";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-launcher";
    rev = version;
    sha256 = "14l9myz4jqxqi5a3y8cf03pxfixmwmhmnrkcxllhwi6fzi22lyxz";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtdeclarative
    qt5.qtwayland
    qt5.qtsensors
    qml-asteroid
  ];

  meta = with lib; {
    description = "AsteroidOS Wayland compositor and smartwatch home shell";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
