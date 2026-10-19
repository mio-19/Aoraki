{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkIf;
  screenCfg = config.mobile.hardware.screen;
  watchCfg = config.mobile.hardware.watch;
  devName =
    if config.mobile ? device && config.mobile.device ? name then
      config.mobile.device.name
    else
      "generic";

  # Generates standard /etc/asteroid/machine.conf expected by AsteroidOS launcher,
  # qml-asteroid, and applications.
  machineConf = pkgs.writeText "machine.conf" ''
    [Display]
    FLAT_TIRE=${toString screenCfg.chinHeight}
    BORDER_GESTURE_WIDTH=15
    ROUND=${if screenCfg.shape == "round" || screenCfg.shape == "chin" then "true" else "false"}
    NEEDS_BURN_IN_PROTECTION=${if watchCfg.burnInProtection then "true" else "false"}

    [Capabilities]
    HAS_WLAN=true
    HAS_SPEAKER=false

    [Identity]
    MACHINE=${devName}
  '';
in
{
  config = mkIf (config.mobile.enable && watchCfg.enable) {
    environment.etc."asteroid/machine.conf".source = machineConf;
  };
}
