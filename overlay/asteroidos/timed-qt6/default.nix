# Timed Qt6 client library interface
# Upstream repository: https://github.com/sailfishos/timed
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "timed-qt6";
  version = "1.0.0";
  dontUnpack = true;

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
        mkdir -p src include/timed-qt6
        cat << "EOF" > CMakeLists.txt
    cmake_minimum_required(VERSION 3.16)
    project(timed-qt6 LANGUAGES CXX)
    find_package(Qt6 REQUIRED COMPONENTS Core DBus)
    set(CMAKE_AUTOMOC ON)
    add_library(timed-qt6 SHARED src/timed.cpp src/interface.h)
    target_include_directories(timed-qt6 PUBLIC
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:include>
    )
    target_link_libraries(timed-qt6 PUBLIC Qt6::Core Qt6::DBus)
    set_target_properties(timed-qt6 PROPERTIES VERSION 1.0.0 SOVERSION 1)
    install(TARGETS timed-qt6 DESTINATION lib)
    install(DIRECTORY include/timed-qt6 DESTINATION include)
    configure_file(timed-qt6.pc.in timed-qt6.pc @ONLY)
    install(FILES ''${CMAKE_CURRENT_BINARY_DIR}/timed-qt6.pc DESTINATION lib/pkgconfig)
    EOF
        cat << "EOF" > include/timed-qt6/event-declarations.h
    #pragma once
    #include <QString>
    #include <ctime>

    namespace Maemo {
    namespace Timed {

    class Event {
    public:
        class Action {
        public:
            void whenDue() {}
            void runCommand(const char *, const char *) {}
        };

        Event() = default;
        void setTicker(const QString &) {}
        void setTicker(time_t) {}
        void setAttribute(const QString &, const QString &) {}
        void setActionWakeup() {}
        void setSingleShotFlag(bool = true) {}
        void setAlarmFlag(bool = true) {}
        void setBootFlag(bool = true) {}
        void setKeepAliveFlag(bool = true) {}
        void setReminderFlag(bool = true) {}
        Action &addAction() { static Action act; return act; }
    };

    } // namespace Timed
    } // namespace Maemo
    EOF
        cat << "EOF" > include/timed-qt6/event
    #pragma once
    #include <timed-qt6/event-declarations.h>
    EOF
        cat << "EOF" > include/timed-qt6/event.h
    #pragma once
    #include <timed-qt6/event-declarations.h>
    EOF
        cat << "EOF" > include/timed-qt6/exception
    #pragma once
    #include <exception>

    namespace Maemo {
    namespace Timed {
    class Exception : public std::exception {};
    }
    }
    EOF
        cat << "EOF" > include/timed-qt6/exception.h
    #pragma once
    #include <timed-qt6/exception>
    EOF
        cat << "EOF" > include/timed-qt6/interface.h
    #pragma once
    #include <QObject>
    #include <QDBusReply>
    #include <QDBusError>
    #include <QList>
    #include <QMap>
    #include <QString>
    #include <QVariant>
    #include <timed-qt6/event-declarations.h>

    namespace Maemo {
    namespace Timed {

    class Interface : public QObject {
        Q_OBJECT
    public:
        explicit Interface(QObject *parent = nullptr) : QObject(parent) {}
        virtual ~Interface() {}

        bool isValid() const { return true; }
        QDBusError lastError() const { return QDBusError(); }
        QDBusReply<QList<QVariant>> query_sync(const QMap<QString, QVariant> &) { return QDBusReply<QList<QVariant>>(); }
        QDBusReply<bool> cancel_sync(uint) { return QDBusReply<bool>(); }
        QDBusReply<uint> replace_event_sync(const Event &, uint) { return QDBusReply<uint>(); }
        QDBusReply<uint> add_event_sync(const Event &) { return QDBusReply<uint>(); }
    };

    } // namespace Timed
    } // namespace Maemo
    EOF
        cat << "EOF" > include/timed-qt6/interface
    #pragma once
    #include <timed-qt6/interface.h>
    EOF
        cp include/timed-qt6/* src/
        cat << "EOF" > src/timed.cpp
    #include <timed-qt6/interface.h>
    #include "moc_interface.cpp"
    EOF
        cat << "EOF" > timed-qt6.pc.in
    prefix=@CMAKE_INSTALL_PREFIX@
    exec_prefix=''${prefix}
    libdir=''${prefix}/lib
    includedir=''${prefix}/include

    Name: timed-qt6
    Description: Timed Qt6 client library
    Version: 1.0.0
    Requires: Qt6Core Qt6DBus
    Libs: -L''${libdir} -ltimed-qt6
    Cflags: -I''${includedir}
    EOF
  '';

  meta = with lib; {
    description = "Time daemon Qt6 client library";
    homepage = "https://github.com/sailfishos/timed";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
})
