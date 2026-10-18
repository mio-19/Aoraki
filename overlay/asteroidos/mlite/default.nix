# Lightweight desktop integration library providing MDConfItem / dconf bindings for Qt
# Upstream repository: https://github.com/sailfishos/mlite
# Packaging reference in AsteroidOS: https://github.com/AsteroidOS/meta-asteroid/tree/master/recipes-nemomobile/mlite
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
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

  preConfigure = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    dconf
    glib
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    description = "MeeGo Touch Framework utilities and configuration item classes";
    homepage = "https://github.com/sailfishos/mlite";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
