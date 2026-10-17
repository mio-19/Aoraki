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

  mobile.device.name = "lg-narwhal";
  mobile.device.identity = {
    name = "Watch W7";
    manufacturer = "LG";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon Wear 2100 (MSM8909W)
    soc = "qualcomm-msm8909w";
    ram = 768;
    screen = {
      width = 360;
      height = 360;
      shape = "round";
    };
    watch = {
      hasCrown = true;
      hasHaptics = true;
      aodSupport = true;
      burnInProtection = false;
    };
  };

  mobile.system.android = {
    device_name = "narwhal";
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
    "androidboot.hardware=narwhal"
    "msm_rtb.filter=0x237"
  ];
}
