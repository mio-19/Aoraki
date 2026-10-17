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

  # Flashing method defaults to fastboot
  mobile.system.android.flashingMethod = mkDefault "fastboot";

  # Default stateVersion
  system.stateVersion = mkDefault "26.11";

  # Common kernel parameters recommended for AsteroidOS android-based kernels
  boot.kernelParams = [
    "loop.max_part=7"
  ];
}
