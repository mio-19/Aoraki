cmake_minimum_required(VERSION 3.16)
project(asteroid-browser VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

include(GNUInstallDirs)

set(SOURCES
    src/main.cpp
    src/webclient.cpp
    src/webclient.h
    src/resources.qrc
)

add_executable(asteroid-browser ${SOURCES})

target_link_libraries(asteroid-browser PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)

install(TARGETS asteroid-browser
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES asteroid-browser.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES asteroid-browser.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    RENAME org.asteroidos.browser.desktop
)

install(FILES asteroid-browser.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)

install(FILES asteroid-browser.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
    RENAME org.asteroidos.browser.svg
)

install(FILES portal.html
    DESTINATION ${CMAKE_INSTALL_DATADIR}/asteroid-browser
)
