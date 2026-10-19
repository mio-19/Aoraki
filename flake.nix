{
  description = "NixOS for Smartwatches";

  outputs =
    { self, ... }:
    let
      all-devices = builtins.filter (d: builtins.pathExists (./. + "/devices/${d}/default.nix")) (
        builtins.attrNames (builtins.readDir ./devices)
      );
    in
    {
      nixosModules =
        builtins.listToAttrs (
          map (device: {
            name = device;
            value = (import ./lib/configuration.nix { inherit device; });
          }) all-devices
        )
        // {
          default = import ./lib/configuration.nix { };
        };

      overlays = {
        default = import ./overlay/default.nix;
        always = import ./overlay/always.nix;
        cross = import ./overlay/cross-compile.nix;
      };
    };
}
