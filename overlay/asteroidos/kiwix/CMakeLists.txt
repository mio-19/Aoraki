cmake_minimum_required(VERSION 3.16)
project(asteroid-kiwix LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBZIM REQUIRED libzim)

add_executable(asteroid-kiwix
    src/main.cpp
    src/zimmanager.cpp
    src/zimmanager.h
    src/zimimageprovider.cpp
    src/zimimageprovider.h
    src/resources.qrc
)

target_include_directories(asteroid-kiwix PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${LIBZIM_INCLUDE_DIRS}
)

target_link_libraries(asteroid-kiwix PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    ${LIBZIM_LIBRARIES}
)

include(GNUInstallDirs)

install(TARGETS asteroid-kiwix
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES org.kiwix.desktop.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES org.kiwix.desktop.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    RENAME asteroid-kiwix.desktop
)

install(FILES kiwix.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)

install(FILES kiwix.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
    RENAME asteroid-kiwix.svg
)
