{ config, lib, pkgs, ... }:

let
  defaultUserName = "watchuser";
in
{
  imports = [
    ./asteroid-desktop.nix
    ../common-configuration.nix
  ];

  config = {
    users.users."${defaultUserName}" = {
      isNormalUser = true;
      password = "1234";
      extraGroups = [
        "dialout"
        "networkmanager"
        "video"
        "wheel"
        "input"
      ];
    };

    services.asteroid-desktop.enable = true;
  };
}
