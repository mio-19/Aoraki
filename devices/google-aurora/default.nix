{
  config,
  lib,
  pkgs,
  ...
}:

let
  auroraBoot = pkgs.callPackage ./boot {
    kernel = config.mobile.boot.stage-1.kernel.package;
    initrd = config.mobile.outputs.initrd;
  };

  inherit (config.mobile.generatedFilesystems) rootfs;

  # Custom fastboot images for Google Pixel Watch 2:
  # Pixel Watch 2 uses Android 13 header v4 boot artifacts:
  # - boot.img: kernel Image only
  # - vendor_kernel_boot.img: vendor ramdisk with early boot kernel modules + DTB
  # - init_boot.img: stage-1 initramfs in lz4
  android-fastboot-images = pkgs.runCommand "android-fastboot-images-google-aurora" { } ''
    mkdir -p $out
    cp -v ${rootfs.imagePath} $out/system.img
    cp -v ${auroraBoot.bootImg} $out/boot.img
    cp -v ${auroraBoot.vendorKernelBootImg} $out/vendor_kernel_boot.img
    cp -v ${auroraBoot.initBootImg} $out/init_boot.img

    cat > $out/flash-critical.sh << 'EOF'
    #!/usr/bin/env bash
    dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")"; echo "$PWD")"
    PS4=" $ "
    echo "Flashing Google Pixel Watch 2 (aurora) boot artifacts..."
    (
      set -x
      fastboot flash --slot=all boot "$dir"/boot.img
      fastboot flash --slot=all vendor_kernel_boot "$dir"/vendor_kernel_boot.img
      fastboot flash --slot=all init_boot "$dir"/init_boot.img
    )
    echo ""
    echo "Flashing completed."
    echo "The system image can be flashed to /userdata or /system via fastboot or sideload."
    EOF
    chmod +x $out/flash-critical.sh
  '';
in
{
  mobile.device.name = "google-aurora";
  mobile.device.identity = {
    name = "Pixel Watch 2";
    manufacturer = "Google";
  };

  # Marked "broken": initial machine configuration ported from AsteroidOS
  # meta-aurora. Out-of-tree vendor modules remain to be integrated.
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

  # Wire in header v4 boot, vendor_kernel_boot, and init_boot images
  mobile.outputs = {
    default = lib.mkForce android-fastboot-images;
    android = {
      android-fastboot-images = lib.mkForce android-fastboot-images;
      android-bootimg = lib.mkForce auroraBoot.bootImg;
    };
  };
}
