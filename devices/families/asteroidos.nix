{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
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

  # Disable heavy desktop/server utilities not used on smartwatches
  programs.command-not-found.enable = mkDefault false;
  services.lvm.enable = mkDefault false;
  boot.bcache.enable = mkDefault false;
  services.logrotate.enable = mkDefault false;
  services.udisks2.enable = mkDefault false;
  environment.defaultPackages = mkDefault [ ];

  # Flashing method defaults to fastboot, destination to userdata partition
  mobile.system.android.flashingMethod = mkDefault "fastboot";
  mobile.system.android.system_partition_destination = mkDefault "userdata";

  # Default stateVersion
  system.stateVersion = mkDefault "26.11";

  # Common kernel parameters recommended for AsteroidOS android-based kernels
  boot.kernelParams = [
    "loop.max_part=7"
  ];

  # Enable zram compressed in-memory swap to avoid OOM on 512MB-1GB smartwatches
  zramSwap = {
    enable = mkDefault true;
    memoryPercent = lib.mkOptionDefault 50;
  };

  # Increase stage-1 failure delay to 60s so errors can be inspected on wrist without immediate reboot
  mobile.boot.stage-1.fail.delay = mkDefault 60;

  # Default to Btrfs root filesystem with transparent Zstandard compression to save eMMC space and reduce wear
  mobile.generatedFilesystems.rootfs.filesystem = lib.mkOverride 900 "btrfs";
}
