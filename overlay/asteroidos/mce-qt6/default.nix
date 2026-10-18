# Qt6 bindings and client library for Mode Control Entity (MCE)
# Upstream repository: https://github.com/sailfishos/libmce-qt
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  mce-dev,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mce-qt6";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libmce-qt";
    rev = "master";
    sha256 = "sha256-xTKBW1G3BZn518IumbUs1yRToEdlbolkeVXJ/8aXBgg=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    mce-dev
  ];

  postPatch = ''
        cat << "EOF" > CMakeLists.txt
    cmake_minimum_required(VERSION 3.16)
    project(mce-qt6 LANGUAGES CXX)
    find_package(Qt6 REQUIRED COMPONENTS Core DBus)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(mce REQUIRED IMPORTED_TARGET mce)
    set(CMAKE_AUTOMOC ON)
    file(GLOB SOURCES "lib/src/*.cpp")
    file(GLOB HEADERS "lib/include/*.h")
    add_library(mce-qt6 SHARED ''${SOURCES} ''${HEADERS} request_interface.cpp signal_interface.cpp)
    target_compile_definitions(mce-qt6 PRIVATE QMCE_LIBRARY)
    target_include_directories(mce-qt6 PUBLIC
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/lib/include>
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}>
      $<INSTALL_INTERFACE:include/mce-qt6>
    )
    target_link_libraries(mce-qt6 PUBLIC Qt6::Core Qt6::DBus PkgConfig::mce)
    set_target_properties(mce-qt6 PROPERTIES VERSION 1.5.1 SOVERSION 1)
    install(TARGETS mce-qt6 DESTINATION lib)
    install(FILES ''${HEADERS} DESTINATION include/mce-qt6)
    configure_file(mce-qt6.pc.in mce-qt6.pc @ONLY)
    install(FILES ''${CMAKE_CURRENT_BINARY_DIR}/mce-qt6.pc DESTINATION lib/pkgconfig)
    EOF
        cat << "EOF" > mce-qt6.pc.in
    prefix=@CMAKE_INSTALL_PREFIX@
    exec_prefix=''${prefix}
    libdir=''${prefix}/lib
    includedir=''${prefix}/include/mce-qt6

    Name: mce-qt6
    Description: Qt bindings for mce
    Version: 1.5.1
    Requires: Qt6Core Qt6DBus mce
    Libs: -L''${libdir} -lmce-qt6
    Cflags: -I''${includedir}
    EOF
  '';

  preConfigure = ''
    ${buildPackages.qt6.qtbase}/bin/qdbusxml2cpp -N -c QMceRequestProxy -p request_interface.h:request_interface.cpp lib/dbus/com.nokia.mce.request.xml
    ${buildPackages.qt6.qtbase}/bin/qdbusxml2cpp -N -c QMceSignalProxy -p signal_interface.h:signal_interface.cpp lib/dbus/com.nokia.mce.signal.xml
  '';

  meta = with lib; {
    description = "Qt6 client library and bindings for Mode Control Entity";
    homepage = "https://github.com/sailfishos/libmce-qt";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
})
