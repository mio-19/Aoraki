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
    environment.systemPackages = with pkgs; [
      asteroid.qml-asteroid
      asteroid.asteroid-launcher
      asteroid.asteroid-btsyncd
      asteroid.apps.stopwatch
      asteroid.apps.timer
      asteroid.apps.alarmclock
      asteroid.apps.calculator
      asteroid.apps.settings
      asteroid.apps.weather
      asteroid.apps.music
      asteroid.apps.compass
      asteroid.apps.flashlight
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
