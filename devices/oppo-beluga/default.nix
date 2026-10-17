{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/asteroidos.nix
  ];

  mobile.device.name = "oppo-beluga";
  mobile.device.identity = {
    name = "OPPO Watch (46mm)";
    manufacturer = "OPPO";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon Wear 3100
    soc = "qualcomm-sda429w";
    ram = 1024 * 1;
    screen = {
      width = 402;
      height = 476;
      shape = "squircle";
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
    };
  };

  mobile.system.android = {
    device_name = "beluga";
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  boot.kernelParams = [
    "console=ttyMSM0,115200,n8"
    "androidboot.console=ttyMSM0"
    "androidboot.hardware=beluga"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "vmalloc=300M"
  ];
}
