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
    # Qualcomm Snapdragon Wear 4100+ (SDA429W / SDM429W), 32-bit Cortex-A7 SoC.
    soc = "qualcomm-sda429w";
    ram = 1024 * 1;
    screen = {
      width = 416;
      height = 416;
    };
    watch = {
      hasCrown = true;
      hasHaptics = true;
      aodSupport = true;
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

  # Kernel parameters matching upstream AsteroidOS / Android bootloader configuration
  # Reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-kernel/linux/linux-hoki/img_info
  boot.kernelParams = [
    "console=ttyMSM0,115200,n8"
    "androidboot.console=ttyMSM0"
    "androidboot.hardware=hoki"
    "androidboot.selinux=permissive"
    "audit=0"
    "user_debug=30"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "androidboot.bootdevice=7824900.sdhci"
    "lpm_levels.sleep_disabled=1"
    "earlycon=msm_serial_dm,0x78b0000"
    "vmalloc=300M"
    "androidboot.usbconfigfs=true"
    "loop.max_part=7"
    "cgroup.memory=nokmem,nosocket"
  ];

  mobile.system.type = "android";

  # Ensure stage-1 udev immediately links userdata to /dev/disk/by-label/NIXOS_SYSTEM
  mobile.boot.stage-1.extraUdevRules = ''
    ENV{ID_PART_ENTRY_NAME}=="userdata", SYMLINK+="disk/by-label/NIXOS_SYSTEM"
  '';

  environment.systemPackages = [
    pkgs.alsa-utils
  ];

  # AsteroidOS Wayland compositor & libhybris hwcomposer environment options for hoki
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-asteroid/asteroid-launcher/asteroid-launcher-configs/20-device.conf
  environment.variables = {
    QPA_HWC_FORCE_GLES = "1";
    QPA_HWC2_FORCE_DOZE_UPDATE = "1";
    QT_OPENGL_NO_BGRA = "1";
    LIPSTICK_OPTIONS = "-plugin evdevkeyboard:/dev/input/event4:keymap=/usr/share/qt6/keymaps/keys.qmap -plugin evdevkeyboard:/dev/input/event0:keymap=/usr/share/qt6/keymaps/keys.qmap -plugin evdevmouse:/dev/input/event1";
  };

  # Hardware node permissions and symlinks for Android HAL / libhybris
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-android/android-init/android-init/init.rc
  services.udev.extraRules = ''
    KERNEL=="hwbinder", MODE="0666"
    KERNEL=="vndbinder", MODE="0666"
    KERNEL=="mdss_rotator", MODE="0666"
    SUBSYSTEM=="leds", KERNEL=="vibrator", ATTR{trigger}="transient", MODE="0666"
    DEVPATH=="/devices/platform/soc/soc:qcom,bg-rsb", ATTR{enable}=="*", MODE="0666"
  '';

  # Persistent hardware partition mounts on Fossil Gen 6 eMMC
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-core/base-files/base-files/fstab
  fileSystems = {
    "/persist" = {
      device = "/dev/disk/by-partlabel/persist";
      fsType = "ext4";
      options = [
        "nofail"
        "errors=continue"
      ];
    };
    "/vendor/firmware_mnt" = {
      device = "/dev/disk/by-partlabel/modem";
      fsType = "vfat";
      options = [
        "ro"
        "shortname=lower"
        "nofail"
      ];
    };
    "/vendor/bt_firmware" = {
      device = "/dev/disk/by-partlabel/bluetooth";
      fsType = "vfat";
      options = [
        "ro"
        "shortname=lower"
        "nofail"
      ];
    };
  };

  # Subsystem boots and firmware mount setup
  # GNSS vendor service symlink PR: https://github.com/AsteroidOS/meta-smartwatch/pull/342
  systemd.tmpfiles.rules = [
    "L+ /system/lib/hw/gps.default.so - - - - /vendor/lib/hw/gps.default.so"
    "L+ /vendor/bin/hw/android.hardware.gnss@1.0-service - - - - /vendor/bin/hw/android.hardware.gnss@1.0-service-qti"
    "L+ /dev/graphics/fb0 - - - - /dev/fb0"
    "d /mnt/vendor 0755 root root -"
    "L+ /mnt/vendor/persist - - - - /persist"
    "d /data/vendor 0755 root root -"
    "d /data/vendor/ssrdump 0755 root root -"
    "d /data/vendor/bgdaemon 0755 root root -"
  ];

  # Fossil Gen 6 Qualcomm ADSP, CDSP, and SLPI subsystem initialization
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-android/android-init/android-init/init.rc
  systemd.services.subsystems-hoki = {
    description = "Fossil Gen 6 Qualcomm ADSP/CDSP/SLPI subsystem boot";
    wantedBy = [ "basic.target" ];
    before = [ "wlan-firmware-hoki.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "subsystems-hoki-init" ''
        for i in 0 1 2 3 4; do
          if [ -f "/sys/bus/msm_subsys/devices/subsys$i/restart_level" ]; then
            echo RELATED > "/sys/bus/msm_subsys/devices/subsys$i/restart_level" 2>/dev/null || true
          fi
        done
        for sub in adsp cdsp slpi; do
          if [ -f "/sys/kernel/boot_$sub/boot" ]; then
            echo 1 > "/sys/kernel/boot_$sub/boot" 2>/dev/null || true
          fi
        done
        # Qualcomm Blackghost RSB companion processor bus permissions and init
        if [ -f "/sys/devices/platform/soc/soc:qcom,bg-rsb/enable" ]; then
          chmod 0666 /sys/devices/platform/soc/soc:qcom,bg-rsb/enable 2>/dev/null || true
        fi
        if [ -x "/vendor/bin/init.rsb.sh" ]; then
          /vendor/bin/init.rsb.sh 2>/dev/null || true
        fi
      '';
    };
  };

  # Fossil Gen 6 CPU/GPU underclock and power collapse profile
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-core/underclock/underclock/underclock
  # Commit: https://github.com/AsteroidOS/meta-smartwatch/commit/8c1dbee6c37cdd4ad97d083a59085abf7032ad42
  systemd.services.underclock-hoki = {
    description = "Fossil Gen 6 low power collapse and CPU underclocking";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 20";
      ExecStart = pkgs.writeShellScript "underclock-hoki" ''
        # Enable low power mode & allow system-pc
        if [ -f /sys/module/lpm_levels/parameters/sleep_disabled ]; then
          echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled 2>/dev/null || true
        fi
        if [ -f /sys/module/lpm_levels/system/system-pc/idle_enabled ]; then
          echo 0 > /sys/module/lpm_levels/system/system-pc/idle_enabled 2>/dev/null || true
        fi
        # Set CPU governor to ondemand for quick burst responses
        if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
          echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
        fi
        # Disable secondary cores to save battery on wrist
        for c in 1 2 3; do
          if [ -f /sys/devices/system/cpu/cpu$c/online ]; then
            echo 0 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null || true
          fi
        done
      '';
    };
  };

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

  # Non-graphic feedback (haptics) DRV260X configuration for tactile feedback
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-nemomobile/ngfd/ngfd/51-ffmemless.ini
  environment.etc."ngf/51-ffmemless.ini".source = ./51-ffmemless.ini;

  # Near Field Communication (NFC) controller configuration
  # Upstream reference: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-nemomobile/libnci/libncicore/libncicore.conf
  environment.etc."libncicore.conf".source = ./libncicore.conf;

  # Audio support on Fossil Gen 6 (hoki) is handled natively via Android Audio HAL (audio.primary.sdm429w.so)
  # and pulseaudio-modules-droid with `source_channel_map=mono rate=48000` (48 kHz DSP frontend clock).
  # Upstream PR (Merged): https://github.com/AsteroidOS/meta-smartwatch/pull/357 ("hoki: Fix microphone and speaker")
}
