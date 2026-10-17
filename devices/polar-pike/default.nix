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

  mobile.device.name = "polar-pike";
  mobile.device.identity = {
    name = "M600";
    manufacturer = "Polar";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # MediaTek MT2601
    soc = "mediatek-mt2601";
    ram = 512;
    screen = {
      width = 240;
      height = 240;
      shape = "square";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "pike";
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
    "androidboot.hardware=pike"
  ];
}
