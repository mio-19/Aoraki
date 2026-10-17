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

  mobile.device.name = "casio-koi";
  mobile.device.identity = {
    name = "Smart Outdoor Watch (WSD-F10/F20)";
    manufacturer = "Casio";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Samsung Exynos 3250
    soc = "samsung-exynos3250";
    ram = 512;
    screen = {
      width = 320;
      height = 300;
      shape = "chin";
      chinHeight = 20;
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "koi";
    bootimg.flash = {
      offset_base = "0x10000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=ttySAC2,115200"
    "androidboot.hardware=koi"
  ];
}
