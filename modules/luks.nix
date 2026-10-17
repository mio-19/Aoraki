{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (config.boot.initrd) luks;
  watchLuks = config.mobile.luks;
in

{
  options.mobile.luks = {
    enable = mkEnableOption "smartwatch LUKS encrypted storage with touchscreen PIN unlock";
    device = mkOption {
      type = types.str;
      default = "/dev/disk/by-partlabel/userdata";
      description = "Block device path to unlock with LUKS in stage-1 initrd.";
    };
    mapper = mkOption {
      type = types.str;
      default = "cryptroot";
      description = "Device-mapper name after unlocking.";
    };
    allowDiscards = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow TRIM discards on the encrypted block device.";
    };
  };

  config = mkMerge [
    (mkIf watchLuks.enable {
      boot.initrd.luks.devices.${watchLuks.mapper} = {
        device = watchLuks.device;
        allowDiscards = watchLuks.allowDiscards;
      };
      mobile.boot.stage-1.gui.pinPad = mkDefault true;
    })
    (mkIf (luks.devices != { } || luks.forceLuksSupportInInitrd) {
      mobile.boot.stage-1 = {
        bootConfig = {
          luksDevices = luks.devices;
        };
        kernel = {
          modules = [ "dm_mod" ];
          additionalModules = [
            "dm_mod"
            "dm_crypt"
            "cryptd"
            "input_leds"
          ]
          ++ luks.cryptoModules;
        };

        extraUtils = [
          { package = pkgs.cryptsetup; }
          # dmsetup is required for device mapper stuff to work in stage-1.
          {
            package = lib.getBin pkgs.lvm2;
            binaries = [
              "lvm"
              "dmsetup"
            ];
          }
        ];
      };
    })
  ];
}
