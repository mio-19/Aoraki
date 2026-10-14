{
  config,
  lib,
  pkgs,
  ...
}:

{
  mobile.device.name = "google-aurora";
  mobile.device.identity = {
    name = "Pixel Watch 2";
    manufacturer = "Google";
  };

  # Marked "broken": initial machine configuration ported from AsteroidOS
  # meta-aurora (da2f9f0743fd556f1ba89007bf9988fc1789fde6). Kernel, out-of-tree
  # vendor modules, and vendor_kernel_boot packaging remain to be integrated.
  mobile.device.supportLevel = "broken";

  mobile.hardware = {
    # Qualcomm Snapdragon W5 Gen 1 (SW5100 / Monaco), quad-core Cortex-A53.
    soc = "qualcomm-sw5100";
    ram = 1024 * 2;
    screen = {
      width = 384;
      height = 384;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android = {
    device_name = "aurora";
    ab_partitions = true;
    bootimg.flash = {
      offset_base = "0x10000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  boot.kernelParams = [
    "systempart=/dev/mapper/system"
    "datapart=/dev/mmcblk0p82"
    "console=tty0"
  ];

  mobile.system.type = "android";
}
