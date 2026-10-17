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

  mobile.device.name = "lg-nemo";
  mobile.device.identity = {
    name = "Watch Urbane 2nd Edition";
    manufacturer = "LG";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon 400 (MSM8926)
    soc = "qualcomm-msm8926";
    ram = 768;
    screen = {
      width = 480;
      height = 480;
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
    device_name = "nemo";
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
    "androidboot.hardware=nemo"
    "msm_rtb.filter=0x237"
  ];
}
