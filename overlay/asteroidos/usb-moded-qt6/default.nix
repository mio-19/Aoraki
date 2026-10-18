# Qt6 bindings and client library for usb-moded daemon
# Upstream repository: https://github.com/sailfishos/libusb-moded-qt
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  dbus,
  buildPackages,
}:

let
  usb-moded-dev = stdenv.mkDerivation (finalAttrs: {
    pname = "usb-moded-dev";
    version = "nightly";

    src = fetchFromGitHub {
      owner = "sailfishos";
      repo = "usb-moded";
      rev = "master";
      sha256 = "sha256-fv5jurY/ulGfWIc4VbTeuyVNs/QqNyxzC6Hyb6amg9c=";
    };

    strictDeps = true;

    installPhase = ''
      mkdir -p $out/include/usb-moded $out/lib/pkgconfig
      cp src/com.meego.usb_moded.xml $out/include/usb-moded/
      cp src/usb_moded*.h $out/include/usb-moded/
      sed -e "s|@VERSION@|0.86.0|" \
          -e "s|prefix=/usr|prefix=$out|" \
          usb_moded.pc.in > $out/lib/pkgconfig/usb_moded.pc
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "usb-moded-qt6";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libusb-moded-qt";
    rev = "master";
    sha256 = "sha256-hCNbpJQz/0Vja7lZTk8zJvEYxt3jCDZoSv4XPTdbBZs=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    usb-moded-dev
    dbus
  ];

  postPatch = ''
        cat << "EOF" > CMakeLists.txt
    cmake_minimum_required(VERSION 3.16)
    project(usb-moded-qt6 LANGUAGES CXX)
    find_package(Qt6 REQUIRED COMPONENTS Core DBus)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(dbus-1 REQUIRED IMPORTED_TARGET dbus-1)
    pkg_check_modules(usb_moded REQUIRED IMPORTED_TARGET usb_moded)
    set(CMAKE_AUTOMOC ON)
    file(GLOB HEADERS "src/*.h")
    set(SOURCES src/qusbmode.cpp src/qusbmoded.cpp usb_moded_interface.cpp)
    add_library(usb-moded-qt6 SHARED ''${SOURCES} ''${HEADERS})
    target_compile_definitions(usb-moded-qt6 PRIVATE QUSBMODED_LIBRARY)
    target_include_directories(usb-moded-qt6 PUBLIC
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/src>
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}>
      $<INSTALL_INTERFACE:include/usb-moded-qt6>
    )
    target_link_libraries(usb-moded-qt6 PUBLIC Qt6::Core Qt6::DBus PkgConfig::dbus-1 PkgConfig::usb_moded)
    set_target_properties(usb-moded-qt6 PROPERTIES VERSION 1.0.0 SOVERSION 1)
    install(TARGETS usb-moded-qt6 DESTINATION lib)
    install(FILES ''${HEADERS} DESTINATION include/usb-moded-qt6)
    configure_file(usb-moded-qt6.pc.in usb-moded-qt6.pc @ONLY)
    install(FILES ''${CMAKE_CURRENT_BINARY_DIR}/usb-moded-qt6.pc DESTINATION lib/pkgconfig)
    EOF
        cat << "EOF" > usb-moded-qt6.pc.in
    prefix=@CMAKE_INSTALL_PREFIX@
    exec_prefix=''${prefix}
    libdir=''${prefix}/lib
    includedir=''${prefix}/include/usb-moded-qt6

    Name: usb-moded-qt6
    Description: Qt bindings for usb_moded
    Version: 1.0.0
    Requires: Qt6Core Qt6DBus
    Libs: -L''${libdir} -lusb-moded-qt6
    Cflags: -I''${includedir}
    EOF
  '';

  preConfigure = ''
    ${buildPackages.qt6.qtbase}/bin/qdbusxml2cpp -N -c QUsbModedInterface -p usb_moded_interface.h:usb_moded_interface.cpp ${usb-moded-dev}/include/usb-moded/com.meego.usb_moded.xml
  '';

  meta = with lib; {
    description = "Qt6 client library and bindings for usb_moded daemon";
    homepage = "https://github.com/sailfishos/libusb-moded-qt";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
})
