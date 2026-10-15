{
  lib,
  pkgs,
  kernel,
  initrd,
}:

let
  inherit (pkgs) buildPackages;

  # mkbootimg geometry from AsteroidOS aurora machine / boot-images recipe
  flash = {
    base = "0x10000000";
    kernel_offset = "0x00008000";
    ramdisk_offset = "0x01000000";
    tags_offset = "0x00000100";
    dtb_offset = "0x01f00000";
    pagesize = "4096";
  };

  # Step 1: Patched DTB with ramoops and continuous-splash framebuffer nodes injected
  dtb =
    pkgs.runCommand "aurora-dtb-ramoops.dtb"
      {
        nativeBuildInputs = [ buildPackages.dtc ];
      }
      ''
        cp ${./static/vkb-base.dtb} $out
        chmod +w $out

        # Ramoops node
        fdtput -c $out /reserved-memory/ramoops@61F00000
        fdtput -t s $out /reserved-memory/ramoops@61F00000 compatible ramoops
        fdtput $out /reserved-memory/ramoops@61F00000 no-map
        fdtput -t x $out /reserved-memory/ramoops@61F00000 reg 0 0x61f00000 0 0x400000
        fdtput -t x $out /reserved-memory/ramoops@61F00000 record-size 0x40000
        fdtput -t x $out /reserved-memory/ramoops@61F00000 console-size 0x200000
        fdtput -t x $out /reserved-memory/ramoops@61F00000 pmsg-size 0x100000

        # Continuous-splash framebuffer node (384x384, stride 1536)
        fdtput -c $out /cont-splash-fb
        fdtput -t s $out /cont-splash-fb compatible "qcom,cont-splash-fb"
        fdtput -t x $out /cont-splash-fb reg 0 0x5c000000 0 0x90000
        fdtput -t u $out /cont-splash-fb width 384
        fdtput -t u $out /cont-splash-fb height 384
        fdtput -t u $out /cont-splash-fb stride 1536
        fdtput -t s $out /cont-splash-fb format "x8r8g8b8"
      '';

  # Step 2: Assemble the vendor_kernel_boot ramdisk (modules + metadata)
  vkbRamdisk =
    pkgs.runCommand "aurora-vkb-ramdisk"
      {
        nativeBuildInputs = [
          buildPackages.python3
          buildPackages.cpio
          buildPackages.lz4
        ];
      }
      ''
        mkdir -p vkb_staging/lib/modules
        # Copy static modules metadata
        cp ${./static/modules.alias} vkb_staging/lib/modules/modules.alias
        cp ${./static/modules.dep} vkb_staging/lib/modules/modules.dep
        cp ${./static/modules.load.charger} vkb_staging/lib/modules/modules.load.charger
        cp ${./static/modules.softdep} vkb_staging/lib/modules/modules.softdep
        cp ${./modules.load.aurora} vkb_staging/lib/modules/modules.load
        cp ${./modules.load.aurora} vkb_staging/lib/modules/modules.load.recovery

        # Copy all built kernel modules from kernel package
        if [ -d "${kernel}/lib/modules" ]; then
          find "${kernel}/lib/modules" -name '*.ko' -exec cp -v {} vkb_staging/lib/modules/ \;
        fi

        # Pack into cpio.lz4
        (
          cd vkb_staging
          find . | sort | cpio -o -H newc --owner root:root 2>/dev/null
        ) | lz4 -l -9 > $out
      '';

  # Step 3: vendor_kernel_boot.img (header v4)
  vendorKernelBootImg =
    pkgs.runCommand "vendor_kernel_boot.img"
      {
        nativeBuildInputs = [ buildPackages.mkbootimg ];
      }
      ''
        mkbootimg \
          --header_version 4 \
          --pagesize ${flash.pagesize} \
          --vendor_boot $out \
          --vendor_ramdisk ${vkbRamdisk} \
          --dtb ${dtb} \
          --base ${flash.base} \
          --kernel_offset ${flash.kernel_offset} \
          --ramdisk_offset ${flash.ramdisk_offset} \
          --tags_offset ${flash.tags_offset} \
          --dtb_offset ${flash.dtb_offset} \
          --vendor_cmdline ""
      '';

  # Step 4: boot.img (header v4: kernel only, empty ramdisk)
  bootImg =
    pkgs.runCommand "aurora-boot.img"
      {
        nativeBuildInputs = [ buildPackages.mkbootimg ];
      }
      ''
        touch empty_ramdisk
        mkbootimg \
          --header_version 4 \
          --kernel ${kernel}/Image \
          --ramdisk empty_ramdisk \
          --cmdline "" \
          -o $out
      '';

  # Step 5: init_boot.img (header v4: empty kernel, stage-1 initrd in lz4)
  initBootImg =
    pkgs.runCommand "aurora-init_boot.img"
      {
        nativeBuildInputs = [
          buildPackages.mkbootimg
          buildPackages.lz4
          buildPackages.gzip
        ];
      }
      ''
        touch empty_kernel
        gunzip -c ${initrd} | lz4 -l -9 > init_boot_rd.lz4
        mkbootimg \
          --header_version 4 \
          --kernel empty_kernel \
          --ramdisk init_boot_rd.lz4 \
          --cmdline "" \
          -o $out
      '';
in
{
  inherit
    dtb
    vkbRamdisk
    vendorKernelBootImg
    bootImg
    initBootImg
    ;
}
