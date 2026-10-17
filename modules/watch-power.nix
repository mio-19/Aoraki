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
    mkOption
    types
    ;

  watchCfg = config.mobile.hardware.watch;
in
{
  options.mobile.hardware.watch.powerManagement = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable battery and low-RAM optimizations tailored for smartwatches:
        zram swap, aggressive pagecache flushing, volatile journald to reduce flash writes,
        and battery conservation.
      '';
    };
  };

  config = mkIf (config.mobile.enable && watchCfg.enable && watchCfg.powerManagement.enable) {
    # Smartwatches have constrained RAM (often 512MB to 2GB).
    # Enable zram with high compression to prevent out-of-memory kills.
    zramSwap = {
      enable = mkDefault true;
      algorithm = mkDefault "zstd";
      memoryPercent = mkDefault 100;
    };

    # Systemd journal volatile storage reduces write cycles on watch eMMC/UFS storage
    # and saves flash controller power draw.
    services.journald.settings.Journal = {
      Storage = "volatile";
      RuntimeMaxUse = "16M";
    };

    # Sysctl kernel tuning for battery life and wrist devices
    boot.kernel.sysctl = {
      # Proactively compress idle anonymous memory into zram
      "vm.swappiness" = mkDefault 100;
      # Reduce dirty page age before flush
      "vm.dirty_writeback_centisecs" = mkDefault 1500;
      "vm.dirty_expire_centisecs" = mkDefault 3000;
    };

    # Power savings: enable CPU frequency governor powersave / schedutil
    powerManagement.cpuFreqGovernor = mkDefault "schedutil";
  };
}
