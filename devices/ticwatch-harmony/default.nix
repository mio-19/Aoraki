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

  mobile.device.name = "ticwatch-harmony";
  mobile.device.identity = {
    name = "KW68 / MTK6580 (Round)";
    manufacturer = "Kingwear";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # MediaTek MT6580
    soc = "mediatek-mt6580";
    ram = 512;
    screen = {
      width = 400;
      height = 400;
      shape = "round";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = false;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "harmony";
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
    "androidboot.hardware=harmony"
  ];
}
