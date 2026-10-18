{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkMerge
    mkOption
    mkIf
    types
    ;
  cfg = config.mobile.hardware.socs;
  anyExynos = lib.any (v: v) [
    cfg.exynos-7880.enable
    cfg.samsung-exynos3250.enable
  ];
in
{
  options.mobile = {
    hardware.socs.exynos-7880.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Exynos 7880";
    };
    hardware.socs.samsung-exynos3250.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Exynos 3250";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.exynos-7880.enable {
        system.system = "aarch64-linux";
        quirks.fb-refresher.enable = true;
      };
    }
    {
      mobile = mkIf cfg.samsung-exynos3250.enable {
        system.system = "armv7l-linux";
      };
    }
    (mkIf anyExynos {
      mobile.kernel.structuredConfig = [
        (
          helpers: with helpers; {
            ARCH_EXYNOS = lib.mkDefault yes;
          }
        )
      ];
    })
  ];
}
