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

  mobile.device.name = "ticwatch-mooneye";
  mobile.device.identity = {
    name = "TicWatch E & S";
    manufacturer = "Mobvoi";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # MediaTek MT2601
    soc = "mediatek-mt2601";
    ram = 512;
    screen = {
      width = 400;
      height = 400;
      shape = "round";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
      burnInProtection = true;
    };
  };

  mobile.system.android = {
    device_name = "mooneye";
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
    "androidboot.hardware=mooneye"
  ];
}
