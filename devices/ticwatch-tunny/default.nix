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

  mobile.device.name = "ticwatch-tunny";
  mobile.device.identity = {
    name = "TicWatch E2 / S2";
    manufacturer = "Mobvoi";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon Wear 2100 (MSM8909W)
    soc = "qualcomm-msm8909w";
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
    device_name = "tunny";
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x01e00000";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "console=ttyMSM0,115200,n8"
    "androidboot.console=ttyMSM0"
    "androidboot.hardware=tunny"
    "msm_rtb.filter=0x237"
  ];
}
