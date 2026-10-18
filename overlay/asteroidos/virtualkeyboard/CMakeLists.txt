cmake_minimum_required(VERSION 3.20)
project(asteroid-virtualkeyboard VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick VirtualKeyboard)
find_package(PkgConfig REQUIRED)
pkg_check_modules(RIME REQUIRED rime)

qt_add_qml_module(qtvkbrimeplugin
    URI "QtQuick.VirtualKeyboard.Plugins.Rime"
    VERSION 1.0
    PLUGIN_TARGET qtvkbrimeplugin
    SOURCES
        rimeinputmethod.h
        rimeinputmethod.cpp
)

target_include_directories(qtvkbrimeplugin PRIVATE ${RIME_INCLUDE_DIRS})
target_link_libraries(qtvkbrimeplugin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::VirtualKeyboard
    ${RIME_LIBRARIES}
)

include(GNUInstallDirs)

install(TARGETS qtvkbrimeplugin
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/qt-6/qml/QtQuick/VirtualKeyboard/Plugins/Rime"
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/qt-6/qml/QtQuick/VirtualKeyboard/Plugins/Rime"
    OPTIONAL
)

# Install watch layouts
install(DIRECTORY layouts/
    DESTINATION "${CMAKE_INSTALL_DATADIR}/qtvirtualkeyboard/layouts"
)
