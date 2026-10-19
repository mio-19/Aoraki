{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    ;
  cfg = config.mobile.hardware.watch.debug;
in
{
  mobile.system.type = mkDefault "android";

  mobile.hardware.watch = {
    enable = mkDefault true;
    hasHaptics = mkDefault true;
    aodSupport = mkDefault true;
    burnInProtection = mkDefault true;
    powerManagement.enable = mkDefault true;
  };

  # Smartwatches flash fixed system/userdata partitions via fastboot;
  # growPartition must be disabled to avoid pulling 64-bit qemu-utils into 32-bit ARMv7 targets.
  boot.growPartition = lib.mkForce false;

  # Display quirks for Qualcomm MDSS framebuffer and DSI command-mode panels
  mobile.quirks.fb-refresher.enable = mkDefault true;
  mobile.quirks.fb-refresher.stage-1.enable = mkDefault true;
  mobile.quirks.qualcomm.fb-notify.enable = mkDefault true;

  # Ensure display is unblanked and backlight is active on boot
  boot.postBootCommands = ''
    # Unblank display panel
    if [ -e /sys/class/graphics/fb0/blank ]; then
      echo 0 > /sys/class/graphics/fb0/blank || true
    fi

    # Set display backlight brightness (~50%)
    for bl in /sys/class/backlight/* /sys/class/leds/*backlight; do
      if [ -e "$bl/max_brightness" ]; then
        max=$(cat "$bl/max_brightness")
        echo $(( max / 2 )) > "$bl/brightness" || true
      elif [ -e "$bl/brightness" ]; then
        echo 50 > "$bl/brightness" || true
      fi
    done
  '';

  # Downstream Android/AsteroidOS vendor kernels use specialized defconfigs (disabling desktop VT, etc.)
  # Reference: https://github.com/AsteroidOS/meta-smartwatch/tree/master/meta-hoki/recipes-kernel/linux
  mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkForce false;

  # Watches are embedded appliances; disable installer tools to shrink image and avoid heavy cross-compilation
  system.disableInstallerTools = mkDefault true;

  # Disable documentation and manual pages on constrained smartwatch storage to shrink closure
  documentation = {
    enable = mkDefault false;
    man.enable = mkDefault false;
    doc.enable = mkDefault false;
    info.enable = mkDefault false;
    nixos.enable = mkDefault false;
  };

  # Disable heavy desktop/server utilities and editors not used on smartwatches
  programs.nano.enable = mkDefault false;
  programs.command-not-found.enable = mkDefault false;
  services.lvm.enable = mkDefault false;
  boot.bcache.enable = mkDefault false;
  boot.enableContainers = mkDefault false;
  services.logrotate.enable = mkDefault false;
  services.udisks2.enable = mkDefault false;
  services.kmscon.enable = mkDefault false;
  services.resolved.enable = mkDefault false;
  boot.plymouth.enable = lib.mkForce false;
  environment.defaultPackages = mkDefault [ ];

  # Enable aggressive rootfs stripping to fit constrained smartwatch storage
  mobile.rootfs.strip.enable = mkDefault true;

  # Flashing method defaults to fastboot, destination to userdata partition
  mobile.system.android.flashingMethod = mkDefault "fastboot";
  mobile.system.android.system_partition_destination = mkDefault "userdata";

  # Default stateVersion
  system.stateVersion = mkDefault "26.11";

  # Enable zram compressed in-memory swap to avoid OOM on 512MB-1GB smartwatches
  zramSwap = {
    enable = mkDefault true;
    memoryPercent = lib.mkOptionDefault 50;
  };

  # Increase stage-1 failure delay to 60s so errors can be inspected on wrist without immediate reboot
  mobile.boot.stage-1.fail.delay = mkDefault 60;

  # Default to ext4 root filesystem for compatibility across vendor kernels
  mobile.generatedFilesystems.rootfs.filesystem = mkDefault "ext4";

  # Common kernel parameters recommended for AsteroidOS android-based kernels
  # Direct kernel logs and virtual terminal console to screen when debug is enabled
  boot.kernelParams = [
    "loop.max_part=7"
  ]
  ++ lib.optionals cfg.enable [
    "console=tty0"
    "consoleblank=0"
  ];

  # Show boot status and service logs on screen during boot
  mobile.beautification.silentBoot = mkIf cfg.enable (lib.mkForce false);

  # Stage-1 and Stage-2 USB Gadget configuration
  mobile.usb = mkIf cfg.enable {
    mode = mkDefault "gadgetfs";
    idVendor = mkDefault "18d1";
    idProduct = mkDefault "d002";
    gadgetfs.functions = {
      rndis = "ncm.usb0";
    };
  };

  # Enable networking and SSH in Stage-1 for early boot recovery and debug
  mobile.boot.stage-1.networking.enable = mkIf cfg.enable (mkDefault true);
  mobile.boot.stage-1.ssh.enable = mkIf cfg.enable (mkDefault true);

  # Enable OpenSSH server in Stage-2
  services.openssh = mkIf cfg.enable {
    enable = mkDefault true;
    settings = {
      PermitRootLogin = "yes";
      PermitEmptyPasswords = "yes";
    };
  };

  # Disable firewall by default on smartwatch USB network
  networking.firewall.enable = mkIf cfg.enable (mkDefault false);

  # Static IP configuration on USB networking interface (supports 192.168.2.15 and 172.16.42.1)
  networking.interfaces = mkIf cfg.enable {
    usb0.ipv4.addresses = [
      {
        address = "192.168.2.15";
        prefixLength = 24;
      }
      {
        address = "172.16.42.1";
        prefixLength = 24;
      }
    ];
  };

  # Allow passwordless root login for debugging
  users.users.root.password = mkIf cfg.enable "";

  # Ensure USB gadget NCM Ethernet function is bound in Stage-2
  systemd.services.usb-gadget-network = mkIf cfg.enable {
    description = "USB Gadget Ethernet (NCM) Setup";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-usb-gadget" ''
        set -e
        mkdir -p /sys/kernel/config
        mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config
        UDC_DIR="/sys/class/udc"
        if [ -d "$UDC_DIR" ] && [ "$(ls -A "$UDC_DIR" 2>/dev/null)" ]; then
          UDC=$(ls "$UDC_DIR" | head -n 1)
          GADGET_DIR="/sys/kernel/config/usb_gadget/g1"
          if [ ! -d "$GADGET_DIR" ]; then
            mkdir -p "$GADGET_DIR/strings/0x409"
            echo "0x18d1" > "$GADGET_DIR/idVendor"
            echo "0xd002" > "$GADGET_DIR/idProduct"
            echo "AsteroidOS" > "$GADGET_DIR/strings/0x409/manufacturer"
            echo "Smartwatch" > "$GADGET_DIR/strings/0x409/product"
            mkdir -p "$GADGET_DIR/functions/ncm.usb0"
            mkdir -p "$GADGET_DIR/configs/c.1/strings/0x409"
            echo "CDC NCM" > "$GADGET_DIR/configs/c.1/strings/0x409/configuration"
            ln -sf "$GADGET_DIR/functions/ncm.usb0" "$GADGET_DIR/configs/c.1/" 2>/dev/null || true
          fi
          CURRENT_UDC=$(cat "$GADGET_DIR/UDC" 2>/dev/null || true)
          if [ -z "$CURRENT_UDC" ]; then
            echo "$UDC" > "$GADGET_DIR/UDC" || true
          fi
        fi
      '';
    };
  };
}
