cmake_minimum_required(VERSION 3.16)
project(asteroid-browser VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBKIT REQUIRED IMPORTED_TARGET webkitgtk-6.0)
pkg_check_modules(GTK4 REQUIRED IMPORTED_TARGET gtk4)

include(GNUInstallDirs)

set(SOURCES
    src/main.c
)

add_executable(asteroid-browser ${SOURCES})

target_link_libraries(asteroid-browser PRIVATE
    PkgConfig::WEBKIT
    PkgConfig::GTK4
    m
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
