{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../families/asteroidos.nix
  ];

  mobile.device.name = "ticwatch-inharmony";
  mobile.device.identity = {
    name = "MTK6580 (Square)";
    manufacturer = "Generic";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # MediaTek MT6580
    soc = "mediatek-mt6580";
    ram = 512;
    screen = {
      width = 320;
      height = 320;
      shape = "square";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = false;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "inharmony";
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x04000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=tty0"
    "androidboot.hardware=inharmony"
  ];
}
