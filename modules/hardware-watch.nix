{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
  ;

  screenCfg = config.mobile.hardware.screen;
  watchCfg = config.mobile.hardware.watch;
in
{
  options.mobile.hardware.screen = {
    shape = mkOption {
      type = types.enum [ "round" "square" "squircle" "chin" ];
      default =
        if screenCfg.chinHeight > 0 then
          "chin"
        else if screenCfg.width == screenCfg.height then
          "round"
        else
          "square";
      description = ''
        Physical shape of the smartwatch display.
        Controls Wayland clipping boundaries, watchface layouts, and notification card shapes.
      '';
    };

    chinHeight = mkOption {
      type = types.int;
      default = 0;
      description = ''
        Height in pixels of the non-display cutout area at the bottom of the screen
        (e.g., the flat-tire bar on Moto 360 models).
      '';
    };

    radius = mkOption {
      type = types.int;
      default =
        if screenCfg.shape == "round" || screenCfg.shape == "chin" then
          screenCfg.width / 2
        else
          0;
      description = ''
        Corner or circular radius of the screen in pixels.
      '';
    };
  };

  options.mobile.hardware.watch = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this device is a smartwatch. Enables watch-specific input,
        display clipping, thermal limits, and power profiles.
      '';
    };

    hasCrown = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the watch features a rotating crown / rotary encoder.
      '';
    };

    hasHaptics = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the device has a vibration / haptic feedback motor.
      '';
    };

    aodSupport = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable Always-On Display (AOD) ambient low-power refresh mode.
      '';
    };

    burnInProtection = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable OLED pixel shift protection during ambient / AOD mode.
      '';
    };

    thermalLimitWrist = mkOption {
      type = types.int;
      default = 43;
      description = ''
        Maximum acceptable surface temperature in degrees Celsius
        for safe prolonged skin contact on the wrist.
      '';
    };
  };

  config = mkIf (config.mobile.enable && watchCfg.enable) {
    # Environment variables for AsteroidOS / Wayland compositors to configure geometry
    environment.variables = {
      ASTEROID_SCREEN_SHAPE = screenCfg.shape;
      ASTEROID_SCREEN_WIDTH = toString screenCfg.width;
      ASTEROID_SCREEN_HEIGHT = toString screenCfg.height;
      ASTEROID_SCREEN_CHIN = toString screenCfg.chinHeight;
      ASTEROID_SCREEN_RADIUS = toString screenCfg.radius;
      ASTEROID_HAS_CROWN = if watchCfg.hasCrown then "1" else "0";
    };

    # Udev rules for watch hardware:
    # 1. Haptics: grant user access to timed_output or vibrator leds
    # 2. Rotary encoder crown: tag as pointer / scroll wheel
    services.udev.extraRules = ''
      # Smartwatch haptics / vibration motor access
      SUBSYSTEM=="timed_output", KERNEL=="vibrator", MODE="0666"
      SUBSYSTEM=="leds", KERNEL=="*vibrat*", MODE="0666"

      # Smartwatch rotary crown mapping
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="*rotary*", ENV{ID_INPUT_KEY}="1", ENV{ID_INPUT_WHEEL}="1"
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="*crown*", ENV{ID_INPUT_KEY}="1", ENV{ID_INPUT_WHEEL}="1"
    '';
  };
}
