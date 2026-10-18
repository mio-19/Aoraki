{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  kdePackages,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qml-asteroid";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "qml-asteroid";
    rev = "c1905485d4aa22f964273e93a62ef23c27a7754b";
    sha256 = "14l43mnff8a7v1dw1d066i0nvswxmj1la3k6a0mxkyzxhykw68iq";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtshadertools
    qt6.qtwayland
  ];

  postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace-fail 'find_package(Mapplauncherd_qt6 MODULE REQUIRED)' ""
        substituteInPlace src/app/CMakeLists.txt \
          --replace-fail 'Mapplauncherd_qt6::Mapplauncherd_qt6' ""
        substituteInPlace src/app/asteroidapp.cpp \
          --replace-fail '#include <MDeclarativeCache>' '#include <QGuiApplication>
    #include <QQuickView>
    namespace MDeclarativeCache { inline QGuiApplication *qApplication(int &argc, char **argv) { return new QGuiApplication(argc, argv); } inline QQuickView *qQuickView() { return new QQuickView(); } }'

        cat <<'EOF' > cmake/FindMapplauncherd_qt6.cmake
    set(Mapplauncherd_qt6_FOUND TRUE)
    if(NOT TARGET Mapplauncherd_qt6::Mapplauncherd_qt6)
        add_library(Mapplauncherd_qt6::Mapplauncherd_qt6 INTERFACE IMPORTED)
    endif()
    EOF

        cat <<'EOF' > cmake/FindTimed.cmake
    set(Timed_FOUND TRUE)
    set(Timed_LIBRARIES "timed-qt6")
    if(NOT TARGET Timed::Timed)
        add_library(Timed::Timed INTERFACE IMPORTED)
        set_target_properties(Timed::Timed PROPERTIES
            INTERFACE_LINK_LIBRARIES "timed-qt6"
        )
    endif()
    EOF
  '';

  cmakeFlags = [
    "-DWITH_ASTEROIDAPP=ON"
    "-DWITH_CMAKE_MODULES=ON"
    "-DECM_DIR=${kdePackages.extra-cmake-modules}/share/ECM/cmake"
    "-DQt6Quick_DIR=${qt6.qtdeclarative}/lib/cmake/Qt6Quick"
    "-DQt6Qml_DIR=${qt6.qtdeclarative}/lib/cmake/Qt6Qml"
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
  ];

  dontWrapQtApps = true;

  postInstall = ''
        mkdir -p $out/lib/cmake/AsteroidApp6
        cp -r $out/lib/cmake/asteroidapp6/* $out/lib/cmake/AsteroidApp6/ || true

        mkdir -p $out/include
        cat <<'EOF' > $out/include/MDeclarativeCache
    #pragma once
    #include <QGuiApplication>
    #include <QQuickView>

    namespace MDeclarativeCache {
    inline QGuiApplication *qApplication(int &argc, char **argv) { return new QGuiApplication(argc, argv); }
    inline QQuickView *qQuickView() { return new QQuickView(); }
    }
    EOF
        cp $out/include/MDeclarativeCache $out/include/mdeclarativecache.h
  '';

  meta = with lib; {
    description = "QML components, styles, and controls for AsteroidOS";
    homepage = "https://asteroidos.org/";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
  };
})
