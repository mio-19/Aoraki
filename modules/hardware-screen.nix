{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options.mobile.hardware.screen = {
    width = mkOption {
      type = types.int;
      default = 400;
      description = ''
        Width of the device's display in pixels.
      '';
    };
    height = mkOption {
      type = types.int;
      default = 400;
      description = ''
        Height of the device's display in pixels.
      '';
    };
  };
}
