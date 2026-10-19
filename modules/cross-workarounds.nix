{
  config,
  lib,
  ...
}:

# This module adds system-level workarounds and package overlays when cross-compiling.
# Package-level cross-compilation fixes are maintained in `overlay/cross-compile.nix`.
let
  isCross = config.nixpkgs.buildPlatform.system != config.nixpkgs.hostPlatform.system;
in
lib.mkIf isCross (
  lib.mkMerge [
    # All cross-compilation
    {
      # Some Network Manager plugins fail during cross-compilation; disable them for cross builds.
      networking.networkmanager.plugins = lib.mkForce [ ];

      # Cross-compilation package overlay
      nixpkgs.overlays = [
        (import ../overlay/cross-compile.nix)
      ];
    }

    # 32 bit ARM
    (lib.mkIf config.nixpkgs.hostPlatform.isAarch32 {
      # qemu-utils is 64-bit only in Nixpkgs; disable growPartition on 32-bit ARM
      boot.growPartition = lib.mkForce false;
    })
  ]
)
