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

  mobile.device.name = "ticwatch-rubyfish";
  mobile.device.identity = {
    name = "TicWatch Pro 3";
    manufacturer = "Mobvoi";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Qualcomm Snapdragon Wear 4100 (SDA429W / SW4100)
    soc = "qualcomm-sda429w";
    ram = 1024 * 1;
    screen = {
      width = 454;
      height = 454;
    };
    watch = {
      hasCrown = false;
      hasHaptics = true;
      aodSupport = true;
    };
  };

  mobile.system.android = {
    device_name = "rubyfish";
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
    "androidboot.hardware=rubyfish"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "vmalloc=300M"
  ];
}
