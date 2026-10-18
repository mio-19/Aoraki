{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.asteroid-desktop;
  inherit (lib) mkDefault mkEnableOption mkIf;
in
{
  options.services.asteroid-desktop = {
    enable = mkEnableOption "AsteroidOS smartwatch user environment";

    browser = {
      enable = lib.mkEnableOption "AsteroidOS smartwatch web browser";
    };
  };

  config = mkIf cfg.enable {

    # Watch system beautification and silent boot
    mobile.beautification = {
      silentBoot = mkDefault true;
      splash = mkDefault true;
    };

    # Enable Bluetooth and low-energy profiles for companion phone syncing
    hardware.bluetooth = {
      enable = mkDefault true;
      powerOnBoot = mkDefault true;
    };

    # System packages for the watch environment
    environment.systemPackages =
      with pkgs;
      [
        asteroid.qml-asteroid
        asteroid.asteroid-launcher
        asteroid.asteroid-btsyncd
        # Asset suite
        asteroid.assets.wallpapers
        asteroid.assets.sounds
        asteroid.assets.icons
        asteroid.assets.fonts
        asteroid.assets.virtualkeyboard
        asteroid.assets.virtualkeyboard-rime
        # Complete application suite
        asteroid.apps.stopwatch
        asteroid.apps.timer
        asteroid.apps.alarmclock
        asteroid.apps.calculator
        asteroid.apps.settings
        asteroid.apps.weather
        asteroid.apps.music
        asteroid.apps.compass
        asteroid.apps.flashlight
        asteroid.apps.calendar
        asteroid.apps.diamonds
        asteroid.apps.hrm
        asteroid.apps.camera
        asteroid.apps.gps-test
        asteroid.apps.telegram
        asteroid.apps.twenty48
      ]
      ++ lib.optionals cfg.browser.enable [
        asteroid.apps.browser
        asteroid.apps.kiwix
      ]
      ++ (with pkgs; [
        asteroid.community-apps.unofficial-watchfaces
        asteroid.community-apps.blaster
        asteroid.community-apps.dodger
        asteroid.community-apps.health
        asteroid.community-apps.sensorlogd
        asteroid.community-apps.map
        asteroid.community-apps.qmltester
        asteroid.community-apps.skedaddle
        asteroid.community-apps.weatherfetch
        asteroid.community-apps.beatfork
        asteroid.community-apps.benchymark
        asteroid.community-apps.docking-bay
        asteroid.community-apps.heliograph
        asteroid.community-apps.horizon
        asteroid.community-apps.meteormatch
        asteroid.community-apps.pulsar
        asteroid.community-apps.rag
        asteroid.community-apps.shopper
        asteroid.community-apps.toolwatch
        asteroid.community-apps.touchdown
      ]);

    systemd.tmpfiles.rules = [
      "d /var/lib/kiwix 0775 ceres users -"
    ];

    # BlueZ dual-mode controller configuration (simultaneous BLE sync and Classic BT profiles)
    # Reference: https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/src/main.conf
    hardware.bluetooth.settings = {
      General = {
        ControllerMode = "dual";
        DiscoverableTimeout = 180;
      };
    };

    environment.variables = {
      QT_IM_MODULE = "qtvirtualkeyboard";
      QT_VIRTUALKEYBOARD_STYLE = "watch";
      QT_VIRTUALKEYBOARD_LAYOUT_PATH = "${pkgs.asteroid.assets.virtualkeyboard-rime}/share/qtvirtualkeyboard/layouts";
      RIME_SHARED_DATA_DIR = "${pkgs.asteroid.assets.virtualkeyboard-rime}/share/rime-data";
    };

    # Wayland compositor and watchface launcher user service (runs under user session)
    # Upstream reference: https://github.com/AsteroidOS/meta-asteroid/blob/master/recipes-asteroid/asteroid-launcher/asteroid-launcher/asteroid-launcher.service
    systemd.user.services.asteroid-launcher = {
      description = "AsteroidOS Wayland Compositor and Launcher";
      wantedBy = [ "default.target" ];
      environment = {
        QT_IM_MODULE = "qtvirtualkeyboard";
        QT_VIRTUALKEYBOARD_STYLE = "watch";
        QT_VIRTUALKEYBOARD_LAYOUT_PATH = "${pkgs.asteroid.assets.virtualkeyboard-rime}/share/qtvirtualkeyboard/layouts";
        RIME_SHARED_DATA_DIR = "${pkgs.asteroid.assets.virtualkeyboard-rime}/share/rime-data";
      }
      // config.environment.variables;
      serviceConfig = {
        ExecStart = "${pkgs.asteroid.asteroid-launcher}/bin/asteroid-launcher -plugin evdevtouch --systemd";
        Restart = "always";
        RestartSec = "2s";
      };
    };

    # AsteroidOS Bluetooth synchronization daemon service
    systemd.services.asteroid-btsyncd = {
      description = "AsteroidOS Bluetooth Sync Daemon";
      after = [ "bluetooth.service" ];
      wants = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.asteroid.asteroid-btsyncd}/bin/asteroid-btsyncd";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # Kiwix offline Wikipedia/ZIM HTTP server user service
    systemd.user.services.kiwix-serve = {
      description = "Kiwix Offline Encyclopedia HTTP Server";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.asteroid.apps.kiwix}/bin/kiwix-watch --daemon-only";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
