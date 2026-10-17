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

  mobile.device.name = "samsung-rinato";
  mobile.device.identity = {
    name = "Gear 2";
    manufacturer = "Samsung";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Samsung Exynos 3250
    soc = "samsung-exynos3250";
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
      burnInProtection = true;
    };
  };

  mobile.system.android = {
    device_name = "rinato";
    bootimg.flash = {
      offset_base = "0x40000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=ttySAC2,115200"
    "androidboot.hardware=rinato"
  ];
}
