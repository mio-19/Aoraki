cmake_minimum_required(VERSION 3.16)
project(asteroid-telegram VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

include(GNUInstallDirs)

set(SOURCES
    src/main.cpp
    src/telegramclient.cpp
    src/telegramclient.h
    src/chatmodel.cpp
    src/chatmodel.h
    src/messagemodel.cpp
    src/messagemodel.h
    src/resources.qrc
)

add_executable(asteroid-telegram ${SOURCES})

target_link_libraries(asteroid-telegram PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)

install(TARGETS asteroid-telegram
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES asteroid-telegram.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES asteroid-telegram.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)
