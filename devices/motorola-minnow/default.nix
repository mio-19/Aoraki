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

  mobile.device.name = "motorola-minnow";
  mobile.device.identity = {
    name = "Moto 360 (2014)";
    manufacturer = "Motorola";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # TI OMAP 3630
    soc = "ti-omap3630";
    ram = 512;
    screen = {
      width = 320;
      height = 290;
      shape = "chin";
      chinHeight = 30;
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "minnow";
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=ttyO2,115200n8"
    "androidboot.hardware=minnow"
  ];
}
