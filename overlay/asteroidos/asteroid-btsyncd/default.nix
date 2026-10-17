{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  systemd,
  qt6,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "asteroid-btsyncd";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-btsyncd";
    rev = "e14fbcd9a157f0988204e874b03f6f800f89d645";
    sha256 = "15vpd3y817gz8j1d7f56k5g1y3747grsjqc5z7b896n7rs2p8ijc";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6.qtdeclarative
  ];

  buildInputs = [
    systemd
    qt6.qtbase
    qt6.qtdeclarative
  ];

  meta = with lib; {
    description = "Bluetooth Low Energy synchronization daemon for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
