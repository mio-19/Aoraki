{
  config,
  lib,
  pkgs,
  ...
}:

let
  defaultUserName = "ceres";
in
{
  imports = [
    ./asteroid-desktop.nix
    ../common-configuration.nix
  ];

  config = {
    users.users."${defaultUserName}" = {
      isNormalUser = true;
      uid = 1000;
      linger = true;
      password = "1234";
      extraGroups = [
        "audio"
        "bluetooth"
        "dialout"
        "input"
        "networkmanager"
        "systemd-journal"
        "video"
        "wheel"
      ];
    };

    services.asteroid-desktop.enable = true;
  };
}
