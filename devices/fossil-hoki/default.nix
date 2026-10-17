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

  mobile.device.name = "fossil-hoki";
  mobile.device.identity = {
    name = "Gen 6";
    manufacturer = "Fossil";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    # Snapdragon Wear 3100 (SDA429W), a 32-bit Cortex-A7 SoC.
    soc = "qualcomm-sda429w";
    ram = 1024 * 1;
    screen = {
      width = 400;
      height = 400;
    };
    watch = {
      hasCrown = true;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android = {
    device_name = "hoki";
    ab_partitions = true;
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  # The DTB is appended to the kernel image (CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE).
  # 90_dtbs-install.patch copies it flat into $out/dtbs/.
  mobile.system.android.appendDTB = [
    "dtbs/sda429-hoki.dtb"
  ];

  boot.kernelParams = [
    "console=ttyMSM0,115200,n8"
    "androidboot.console=ttyMSM0"
    "androidboot.hardware=hoki"
    "user_debug=30"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "lpm_levels.sleep_disabled=1"
    "earlycon=msm_serial_dm,0x78b0000"
    "vmalloc=300M"
    "loop.max_part=7"
  ];

  mobile.system.type = "android";

  environment.systemPackages = [
    pkgs.alsa-utils
  ];

  # WCNSS Wi-Fi firmware initialization and driver loading
  # Upstream PR: https://github.com/AsteroidOS/meta-smartwatch/pull/341 ("hoki: wlan: working WiFi driver from source")
  systemd.services.wlan-firmware-hoki = {
    description = "Fossil Gen 6 WCNSS WLAN firmware setup";
    wantedBy = [ "multi-user.target" ];
    before = [ "network-pre.target" ];
    path = with pkgs; [
      kmod
      coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "wlan-firmware-hoki" (
        builtins.readFile ./wlan-firmware-hoki.sh
      )}";
    };
  };

  # GNSS AGPS NTP injection configuration & Android HAL library symlink
  # Upstream PR: https://github.com/AsteroidOS/meta-smartwatch/pull/342 ("hoki: gnss: symlink real vendor HAL service, enable NTP AGPS assistance")
  environment.etc."gps_xtra.ini".source = ./gps_xtra.ini;
  systemd.tmpfiles.rules = [
    "L+ /system/lib/hw/gps.default.so - - - - /vendor/lib/hw/gps.default.so"
  ];

  # Audio support on Fossil Gen 6 (hoki) is handled natively via Android Audio HAL (audio.primary.sdm429w.so)
  # and pulseaudio-modules-droid with `source_channel_map=mono rate=48000` (48 kHz DSP frontend clock).
  # Upstream PR (Merged): https://github.com/AsteroidOS/meta-smartwatch/pull/357 ("hoki: Fix microphone and speaker")
}
