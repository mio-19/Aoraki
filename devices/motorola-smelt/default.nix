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

  mobile.device.name = "motorola-smelt";
  mobile.device.identity = {
    name = "Moto 360 (2nd Gen)";
    manufacturer = "Motorola";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon 400 (APQ8026)
    soc = "qualcomm-apq8026";
    ram = 512;
    screen = {
      width = 360;
      height = 325;
      chinHeight = 35;
      shape = "chin";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
    };
  };

  mobile.system.android = {
    device_name = "smelt";
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
    "console=ttyMSM0,115200,n8"
    "androidboot.console=ttyMSM0"
    "androidboot.hardware=smelt"
    "msm_rtb.filter=0x237"
    "vmalloc=300M"
  ];
}
