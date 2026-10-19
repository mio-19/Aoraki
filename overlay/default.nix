# Top-level overlay for NixOS for Smartwatches.
# Composes:
# 1. always.nix: Custom package additions and stacks that always apply.
# 2. cross-compile.nix: Upstream fixes and workarounds that only apply during cross-compilation.
final: super:

let
  always = import ./always.nix final super;
  cross = import ./cross-compile.nix final super;
in
always // cross
