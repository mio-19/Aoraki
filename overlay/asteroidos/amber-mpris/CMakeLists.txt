cmake_minimum_required(VERSION 3.16)
project(amber-mpris VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6Core REQUIRED)
find_package(Qt6DBus REQUIRED)
find_package(Qt6Qml REQUIRED)

include(GNUInstallDirs)

# Static library for qtdbusextended
add_library(qtdbusextended STATIC
    qtdbusextended/dbusextendedabstractinterface.cpp
    qtdbusextended/dbusextendedabstractinterface.h
    qtdbusextended/dbusextended.h
)
target_include_directories(qtdbusextended PUBLIC qtdbusextended)
target_link_libraries(qtdbusextended PUBLIC Qt6::Core Qt6::DBus)
set_target_properties(qtdbusextended PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Shared library ambermpris6
add_library(ambermpris6 SHARED
    src/mpris.cpp
    src/mprisclient.cpp
    src/mpriscontroller.cpp
    src/mprisintrospectableadaptor.cpp
    src/mprismetadata.cpp
    src/mprismetadataproxy.cpp
    src/mprisplayer.cpp
    src/mprisplayeradaptor.cpp
    src/mprisplayerinterface.cpp
    src/mprispropertiesadaptor.cpp
    src/mprisrootinterface.cpp
    src/mprisserviceadaptor.cpp
    src/mpris.h
    src/mpris_p.h
    src/mprisclient.h
    src/mprisclient_p.h
    src/mpriscontroller.h
    src/mprisintrospectableadaptor_p.h
    src/mprismetadata.h
    src/mprismetadata_p.h
    src/mprismetadataproxy.h
    src/mprisplayeradaptor_p.h
    src/mprisplayer.h
    src/mprisplayer_p.h
    src/ambermpris.h
    src/ambermpris_p.h
    src/mprispropertiesadaptor_p.h
    src/mprisserviceadaptor_p.h
)
target_compile_definitions(ambermpris6 PRIVATE MPRIS_QT_LIBRARY)
target_include_directories(ambermpris6 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/qtdbusextended>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/AmberMpris>
)
target_link_libraries(ambermpris6 PUBLIC Qt6::Core Qt6::DBus PRIVATE qtdbusextended)

# QML declarative plugin
add_library(ambermprisplugin SHARED
    declarative/declarativemprisplayer.cpp
    declarative/declarativemprisplayer_p.h
    declarative/mprisplugin.cpp
    declarative/mprisplugin.h
)
target_include_directories(ambermprisplugin PRIVATE src qtdbusextended declarative)
target_link_libraries(ambermprisplugin PRIVATE ambermpris6 Qt6::Core Qt6::DBus Qt6::Qml)

# Headers to install
set(AMBER_HEADERS
    src/Mpris
    src/MprisPlayer
    src/MprisClient
    src/MprisController
    src/MprisMetaData
    src/mpris.h
    src/mprisclient.h
    src/mpriscontroller.h
    src/mprisplayer.h
    src/mprismetadata.h
    src/ambermpris.h
)

install(TARGETS ambermpris6
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES ${AMBER_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/AmberMpris
)

# Install QML plugin into Amber/Mpris
set(QML_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR}/qt-6/qml/Amber/Mpris)
install(TARGETS ambermprisplugin
    DESTINATION ${QML_INSTALL_DIR}
)
install(FILES
    declarative/qmldir
    declarative/plugins.qmltypes
    DESTINATION ${QML_INSTALL_DIR}
)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/example/qml/MprisAudio.qml)
    install(FILES example/qml/MprisAudio.qml DESTINATION ${QML_INSTALL_DIR})
endif()

# Configure and install pkg-config
set(PKG_CONFIG_PREFIX "${CMAKE_INSTALL_PREFIX}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/ambermpris6.pc
"prefix=${PKG_CONFIG_PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include/AmberMpris

Name: AmberMpris
Description: AmberMpris library
Version: 1.0.0
Requires: Qt6Core Qt6DBus
Libs: -L\${libdir} -lambermpris6
Cflags: -I\${includedir}
")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ambermpris6.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)
