{ config, lib, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.mobile.hardware.socs;
  anyQualcomm = lib.any (v: v) [
    cfg.qualcomm-sda429w.enable
    cfg.qualcomm-sw5100.enable
    cfg.qualcomm-apq8064-1aa.enable
    cfg.qualcomm-apq8026.enable
    cfg.qualcomm-msm8926.enable
    cfg.qualcomm-msm8226.enable
    cfg.qualcomm-msm8909w.enable
  ];
in
{
  options.mobile = {
    hardware.socs.qualcomm-apq8064-1aa.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is APQ8064–1AA";
    };
    hardware.socs.qualcomm-sda429w.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is SDA429W (Snapdragon Wear 3100)";
    };
    hardware.socs.qualcomm-sw5100.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is SW5100 (Snapdragon W5 Gen 1)";
    };
    hardware.socs.qualcomm-apq8026.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is APQ8026 (Snapdragon 400 Wear)";
    };
    hardware.socs.qualcomm-msm8909w.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is MSM8909W (Snapdragon Wear 2100)";
    };
    hardware.socs.qualcomm-msm8926.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is MSM8926 (Snapdragon 400)";
    };
    hardware.socs.qualcomm-msm8226.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is MSM8226 (Snapdragon 400)";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.qualcomm-sda429w.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-sw5100.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-apq8064-1aa.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-apq8026.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8909w.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8926.enable {
        system.system = "armv7l-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8226.enable {
        system.system = "armv7l-linux";
      };
    }
    (mkIf anyQualcomm {
      mobile.kernel.structuredConfig = [
        (
          helpers: with helpers; {
            ARCH_QCOM = lib.mkDefault (whenAtLeast "4.1" yes);
            ARCH_MSM = lib.mkDefault (whenOlder "4.1" yes);
          }
        )
      ];
    })
  ];
}
