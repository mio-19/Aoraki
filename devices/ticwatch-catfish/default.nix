{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/asteroidos.nix
  ];

  mobile.device.name = "ticwatch-catfish";
  mobile.device.identity = {
    name = "TicWatch Pro";
    manufacturer = "Mobvoi";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon Wear 2100 (MSM8909W)
    soc = "qualcomm-msm8909w";
    ram = 1024 * 1;
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
    device_name = "catfish";
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
    "androidboot.hardware=catfish"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "vmalloc=300M"
  ];
}
