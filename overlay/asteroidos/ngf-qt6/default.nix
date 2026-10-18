# Qt6 client library for Non-Graphic Feedback (NGF) daemon
# Upstream repository: https://github.com/sailfishos/libngf-qt
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ngf-qt6";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "libngf-qt";
    rev = "master";
    sha256 = "sha256-Spg1PfS0mkLDaCaR7RZUKbne+RFLJ1SSUnIgupfYgMw=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
  ];

  postPatch = ''
        cat << "EOF" > CMakeLists.txt
    cmake_minimum_required(VERSION 3.16)
    project(ngf-qt6 LANGUAGES CXX)
    find_package(Qt6 REQUIRED COMPONENTS Core DBus)
    set(CMAKE_AUTOMOC ON)
    file(GLOB HEADERS "src/include/*")
    set(SOURCES src/dbus/client.cpp src/dbus/clientprivate.cpp)
    add_library(ngf-qt6 SHARED ''${SOURCES} ''${HEADERS})
    target_compile_definitions(ngf-qt6 PRIVATE NGFCLIENT_LIBRARY)
    target_include_directories(ngf-qt6 PUBLIC
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/src/include>
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/src/dbus>
      $<INSTALL_INTERFACE:include/ngf-qt6>
    )
    target_link_libraries(ngf-qt6 PUBLIC Qt6::Core Qt6::DBus)
    set_target_properties(ngf-qt6 PROPERTIES VERSION 1.0.0 SOVERSION 1)
    install(TARGETS ngf-qt6 DESTINATION lib)
    install(FILES ''${HEADERS} DESTINATION include/ngf-qt6)
    configure_file(ngf-qt6.pc.in ngf-qt6.pc @ONLY)
    install(FILES ''${CMAKE_CURRENT_BINARY_DIR}/ngf-qt6.pc DESTINATION lib/pkgconfig)
    EOF
        cat << "EOF" > ngf-qt6.pc.in
    prefix=@CMAKE_INSTALL_PREFIX@
    exec_prefix=''${prefix}
    libdir=''${prefix}/lib
    includedir=''${prefix}/include/ngf-qt6

    Name: ngf-qt6
    Description: Qt client library for NGF daemon
    Version: 1.0.0
    Requires: Qt6Core Qt6DBus
    Libs: -L''${libdir} -lngf-qt6
    Cflags: -I''${includedir}
    EOF
  '';

  meta = with lib; {
    description = "Qt6 client library for Non-Graphic Feedback daemon";
    homepage = "https://github.com/sailfishos/libngf-qt";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
})
