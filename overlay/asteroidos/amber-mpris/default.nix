# QML MPRIS integration library used by AsteroidOS music and btsyncd components
# Upstream repository: https://github.com/sailfishos/amber-mpris
# Packaging reference in AsteroidOS: https://github.com/AsteroidOS/meta-asteroid/tree/master/recipes-qt/amber-mpris
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "amber-mpris";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "amber-mpris";
    rev = "0dc2c15104a13c16f3028cb9e73f1e4dc886f4d0";
    hash = "sha256-kOjzaF6Xu1D06V8Dq9i0mUXwROH0rXTNC2zVnbiYUHI=";
  };

  strictDeps = true;

  preConfigure = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    description = "Qt and QML MPRIS interface and adaptor";
    homepage = "https://github.com/sailfishos/amber-mpris";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
})
