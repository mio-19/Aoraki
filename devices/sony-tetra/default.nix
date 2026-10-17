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

  mobile.device.name = "sony-tetra";
  mobile.device.identity = {
    name = "SmartWatch 3 (SWR50)";
    manufacturer = "Sony";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Broadcom BCM23550
    soc = "broadcom-bcm23550";
    ram = 512;
    screen = {
      width = 320;
      height = 320;
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
    device_name = "tetra";
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=ttyS0,115200"
    "androidboot.hardware=tetra"
  ];
}
