# Nemo keepalive background activity scheduling library
# Upstream repository: https://github.com/sailfishos/nemo-keepalive
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "keepalive";
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
        mkdir -p src include/keepalive
        cat << "EOF" > CMakeLists.txt
    cmake_minimum_required(VERSION 3.16)
    project(keepalive LANGUAGES CXX)
    find_package(Qt6 REQUIRED COMPONENTS Core)
    set(CMAKE_AUTOMOC ON)
    add_library(keepalive SHARED src/backgroundactivity.cpp src/backgroundactivity.h)
    target_include_directories(keepalive PUBLIC
      $<BUILD_INTERFACE:''${CMAKE_CURRENT_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:include>
    )
    target_link_libraries(keepalive PUBLIC Qt6::Core)
    set_target_properties(keepalive PROPERTIES VERSION 1.0.0 SOVERSION 1)
    install(TARGETS keepalive DESTINATION lib)
    install(DIRECTORY include/keepalive DESTINATION include)
    configure_file(keepalive.pc.in keepalive.pc @ONLY)
    install(FILES ''${CMAKE_CURRENT_BINARY_DIR}/keepalive.pc DESTINATION lib/pkgconfig)
    EOF
        cat << "EOF" > include/keepalive/backgroundactivity.h
    #ifndef BACKGROUNDACTIVITY_H_
    #define BACKGROUNDACTIVITY_H_
    #include <QObject>
    #include <QTimer>
    class BackgroundActivity : public QObject {
        Q_OBJECT
        Q_ENUMS(State Frequency)
    public:
        enum State { Stopped, Waiting, Running };
        enum Frequency {
            Range = 0,
            ThirtySeconds = 30,
            TwoAndHalfMinutes = 150,
            FiveMinutes = 300,
            TenMinutes = 600,
            FifteenMinutes = 900,
            ThirtyMinutes = 1800,
            OneHour = 3600,
            TwoHours = 7200,
            FourHours = 14400,
            EightHours = 28800,
            TenHours = 36000,
            TwelveHours = 43200,
            TwentyFourHours = 86400,
            MaximumFrequency = 0x7fffffff
        };
        explicit BackgroundActivity(QObject *parent = nullptr);
        virtual ~BackgroundActivity();
        Frequency wakeupFrequency() const;
        void wakeupRange(int &min_delay, int &max_delay) const;
        bool isWaiting() const;
        bool isRunning() const;
        bool isStopped() const;
        BackgroundActivity::State state() const;
        void setWakeupFrequency(Frequency slot);
        void setWakeupRange(int min_delay, int max_delay);
        void setState(BackgroundActivity::State new_state);
        void wait(Frequency slot);
        void wait(int min_delay, int max_delay = -1);
        QString id() const;
    public Q_SLOTS:
        void wait();
        void run();
        void stop();
    Q_SIGNALS:
        void waiting();
        void running();
        void stopped();
        void stateChanged();
    private Q_SLOTS:
        void onTimeout();
    private:
        State m_state = Stopped;
        Frequency m_frequency = Range;
        int m_minDelay = 0;
        int m_maxDelay = 0;
        QTimer *m_timer;
    };
    #endif
    EOF
        cp include/keepalive/* src/
        cat << "EOF" > src/backgroundactivity.cpp
    #include <keepalive/backgroundactivity.h>
    BackgroundActivity::BackgroundActivity(QObject *parent) : QObject(parent), m_timer(new QTimer(this)) {
        m_timer->setSingleShot(true);
        connect(m_timer, &QTimer::timeout, this, &BackgroundActivity::onTimeout);
    }
    BackgroundActivity::~BackgroundActivity() {}
    BackgroundActivity::Frequency BackgroundActivity::wakeupFrequency() const { return m_frequency; }
    void BackgroundActivity::wakeupRange(int &min_delay, int &max_delay) const { min_delay = m_minDelay; max_delay = m_maxDelay; }
    bool BackgroundActivity::isWaiting() const { return m_state == Waiting; }
    bool BackgroundActivity::isRunning() const { return m_state == Running; }
    bool BackgroundActivity::isStopped() const { return m_state == Stopped; }
    BackgroundActivity::State BackgroundActivity::state() const { return m_state; }
    void BackgroundActivity::setWakeupFrequency(Frequency slot) { m_frequency = slot; }
    void BackgroundActivity::setWakeupRange(int min_delay, int max_delay) { m_minDelay = min_delay; m_maxDelay = max_delay; }
    void BackgroundActivity::setState(BackgroundActivity::State new_state) {
        if (m_state != new_state) {
            m_state = new_state;
            emit stateChanged();
            if (m_state == Waiting) emit waiting();
            else if (m_state == Running) emit running();
            else if (m_state == Stopped) emit stopped();
        }
    }
    void BackgroundActivity::wait(Frequency slot) { setWakeupFrequency(slot); wait((int)slot, (int)slot); }
    void BackgroundActivity::wait(int min_delay, int max_delay) { setWakeupRange(min_delay, max_delay); wait(); }
    void BackgroundActivity::wait() {
        setState(Waiting);
        int delay = (m_minDelay > 0) ? m_minDelay : 10;
        m_timer->start(delay * 1000);
    }
    void BackgroundActivity::run() { m_timer->stop(); setState(Running); }
    void BackgroundActivity::stop() { m_timer->stop(); setState(Stopped); }
    void BackgroundActivity::onTimeout() { run(); }
    QString BackgroundActivity::id() const { return QStringLiteral("activity"); }
    #include "moc_backgroundactivity.cpp"
    EOF
        cat << "EOF" > keepalive.pc.in
    prefix=@CMAKE_INSTALL_PREFIX@
    exec_prefix=''${prefix}
    libdir=''${prefix}/lib
    includedir=''${prefix}/include

    Name: keepalive
    Description: CPU/display keepalive development library
    Version: 1.0.0
    Requires: Qt6Core
    Libs: -L''${libdir} -lkeepalive
    Cflags: -I''${includedir}
    EOF
  '';

  meta = with lib; {
    description = "Nemomobile CPU and display keepalive library";
    homepage = "https://github.com/sailfishos/nemo-keepalive";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
})
