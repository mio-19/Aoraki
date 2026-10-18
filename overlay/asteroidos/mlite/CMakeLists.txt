cmake_minimum_required(VERSION 3.16)
project(mlite VERSION 0.4.10 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core DBus DBusTools)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(DCONF dconf)

include(GNUInstallDirs)

set(SOURCES
    src/mnotification.cpp
    src/mnotificationgroup.cpp
    src/mremoteaction.cpp
    src/mdesktopentry.cpp
    src/mpermission.cpp
    src/mfiledatastore.cpp
    src/logging.cpp
)

set(HEADERS
    src/mnotification.h
    src/mnotificationgroup.h
    src/mremoteaction.h
    src/mdesktopentry.h
    src/mpermission.h
    src/mfiledatastore.h
    src/mlite-global.h
    src/metatypedeclarations.h
    src/logging.h
    src/MNotification
    src/MNotificationGroup
    src/MRemoteAction
    src/MDesktopEntry
    src/MPermission
    src/MExport
)

if(DCONF_FOUND)
    list(APPEND SOURCES
        src/mdconfitem.cpp
        src/mdconf.cpp
        src/mdconfgroup.cpp
        src/mgconfitem.cpp
    )
    list(APPEND HEADERS
        src/mdconfitem.h
        src/mdconfgroup.h
        src/mgconfitem.h
        src/MDConfItem
        src/MDConfGroup
        src/MGConfItem
    )
    add_compile_definitions(HAVE_DCONF)
endif()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/mnotificationmanagerproxy.cpp ${CMAKE_CURRENT_BINARY_DIR}/mnotificationmanagerproxy.h
    COMMAND Qt6::qdbusxml2cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/notificationmanager.xml
        -p ${CMAKE_CURRENT_BINARY_DIR}/mnotificationmanagerproxy
        -c MNotificationManagerProxy
        -i metatypedeclarations.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/notificationmanager.xml
)
list(APPEND SOURCES
    ${CMAKE_CURRENT_BINARY_DIR}/mnotificationmanagerproxy.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/mnotificationmanagerproxy.h
)

add_library(mlite6 SHARED ${SOURCES})

target_include_directories(mlite6 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/mlite6>
    ${GLIB_INCLUDE_DIRS}
)

if(DCONF_FOUND)
    target_include_directories(mlite6 PUBLIC ${DCONF_INCLUDE_DIRS})
    target_link_libraries(mlite6 PUBLIC ${DCONF_LIBRARIES})
endif()

target_link_libraries(mlite6 PUBLIC
    Qt6::Core
    Qt6::DBus
    ${GLIB_LIBRARIES}
)

install(TARGETS mlite6
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES ${HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mlite6
)

set(PKG_CONFIG_PREFIX "${CMAKE_INSTALL_PREFIX}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/mlite6.pc
"prefix=${PKG_CONFIG_PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include/mlite6

Name: mlite6
Description: MeeGo Touch Framework utilities and configuration item classes
Version: 0.4.10
Requires: Qt6Core Qt6DBus
Libs: -L\${libdir} -lmlite6
Cflags: -I\${includedir}
")

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/mlite6.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)
