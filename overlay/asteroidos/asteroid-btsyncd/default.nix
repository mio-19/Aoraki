{ lib
, stdenv
, fetchFromGitHub
, cmake
, extra-cmake-modules
, pkg-config
, glib
, glibmm
, bluez
, systemd
, qt5
}:

stdenv.mkDerivation rec {
  pname = "asteroid-btsyncd";
  version = "2.1";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "asteroid-btsyncd";
    rev = version;
    sha256 = "00cg3gh197rilwqk06vx455w1wgnzakjcwf7k3p46r75fap3hs6h";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
  ];

  buildInputs = [
    glib
    glibmm
    bluez
    systemd
    qt5.qtbase
  ];

  meta = with lib; {
    description = "Bluetooth Low Energy synchronization daemon for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
