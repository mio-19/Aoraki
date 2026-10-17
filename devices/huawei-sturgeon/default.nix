{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/asteroidos.nix
  ];

  mobile.device.name = "huawei-sturgeon";
  mobile.device.identity = {
    name = "Huawei Watch";
    manufacturer = "Huawei";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon 400 (APQ8026)
    soc = "qualcomm-apq8026";
    ram = 512;
    screen = {
      width = 400;
      height = 400;
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
    };
  };

  mobile.system.android = {
    device_name = "sturgeon";
    bootimg.flash = {
      offset_base = "0x00000000";
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
    "androidboot.hardware=sturgeon"
    "msm_rtb.filter=0x237"
    "vmalloc=300M"
  ];
}
