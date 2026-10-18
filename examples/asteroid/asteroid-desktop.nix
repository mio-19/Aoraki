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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install the AsteroidOS web browser package.";
      };
      engine = lib.mkOption {
        type = lib.types.enum [
          "ladybird"
          "servo"
          "netsurf"
          "goanna"
          "webkit"
        ];
        default = "ladybird";
        description = "Rendering engine backend for asteroid-browser built into the watch system.";
      };
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
        # Community application suite & unofficial watchfaces
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
      ]
      ++ lib.optionals cfg.browser.enable [
        (asteroid.browser.override {
          engine = cfg.browser.engine;
        })
      ];

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
  };
}
