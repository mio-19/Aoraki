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

  dontWrapQtApps = true;

  postInstall = ''
    mkdir -p $out/lib/cmake/AsteroidApp6 $out/lib/cmake/asteroidapp6
    cat << 'EOF' > $out/lib/cmake/AsteroidApp6/AsteroidApp6Config.cmake
    get_filename_component(_dir "''${CMAKE_CURRENT_LIST_DIR}/../../../share/asteroidapp/cmake" ABSOLUTE)
    set(ASTEROID_MODULE_PATH "''${_dir}")
    set(AsteroidApp6_FOUND TRUE)
    EOF
    cp $out/lib/cmake/AsteroidApp6/AsteroidApp6Config.cmake $out/lib/cmake/asteroidapp6/asteroidapp6-config.cmake
  '';

  meta = with lib; {
    description = "QML components, styles, and controls for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
  };
}
