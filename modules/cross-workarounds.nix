{
  config,
  lib,
  pkgs,
  ...
}:

# This module adds system-level workarounds when cross-compiling.
# These workarounds are only expected to be implemented for the *basic* build.
# That is `nix-build ./default.nix`, without additional configuration.
let
  isCross = config.nixpkgs.buildPlatform.system != config.nixpkgs.hostPlatform.system;
  nullPackage = pkgs.runCommand "null" { } ''
    mkdir -p $out
  '';
in
lib.mkIf isCross (
  lib.mkMerge [

    # All cross-compilation
    {

      # Some Network Manager plugins are kinda problematic...
      # Let's ignore them for now.
      # Cross-compilation of Mobile NixOS for the time being is not fully-featured.
      # If those plugins are needed, do a native build.
      networking.networkmanager.plugins = lib.mkForce [ ];
    }

    # 32 bit ARM
    (lib.mkIf config.nixpkgs.hostPlatform.isAarch32 {
      nixpkgs.overlays = [
        (
          final: super:
          # Ensure pkgsBuildBuild ends up unmodified, otherwise the canary test will
          # get super expensive to build.
          if super.stdenv.buildPlatform == super.stdenv.hostPlatform then
            { }
          else
            {
              # btrfs-progs-armv7l-unknown-linux-gnueabihf-5.17.drv
              # /nix/store/wnrc4daqbd6v5ifqlxsj75ky8556zy0p-python3-3.9.12/include/python3.9/pyport.h:741:2: error: #error "LONG_BIT definition appears wrong for platform (bad gcc/glibc config?)."
              btrfs-progs = lib.warn "btrfs-progs neutered due to broken build with cross armv7l" nullPackage;

              # systemd BPF framework fails when cross-compiling on 32-bit ARM due to missing linux/types.h in clang target bpf.
              systemd = super.systemd.override { withLibBPF = false; };

              # libpcap pulls in rdma-core (InfiniBand/RoCE), which fails to cross-compile
              # on 32-bit ARM due to CMake Python host/target architecture checks.
              # Smartwatches do not use InfiniBand, so disable RDMA.
              libpcap = super.libpcap.override { withRdma = false; };

              # Skia gnFlags cpu mapping expects "arm" instead of "armv7l".
              # Reference: https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/sk/skia/package.nix
              skia = super.skia.override {
                stdenv = super.stdenv.override (old: {
                  hostPlatform = super.stdenv.hostPlatform // {
                    parsed = super.stdenv.hostPlatform.parsed // {
                      cpu = super.stdenv.hostPlatform.parsed.cpu // {
                        name = "arm";
                      };
                    };
                  };
                });
              };

              # Port Ladybird browser to 32-bit ARM (armv7l):
              # Upstream repository: https://github.com/LadybirdBrowser/ladybird
              # Patches LibGC (NanBoxedValue, HeapRegion, BlockAllocator) to support 32-bit pointers
              # and reduces the heap cage from 4 TiB to 128 MiB to fit 32-bit virtual memory.
              ladybird =
                (super.ladybird.override {
                  skia = final.skia;
                }).overrideAttrs
                  (old: {
                    patches = (old.patches or [ ]) ++ [
                      ../overlay/ladybird/0001-32bit-support.patch
                    ];
                    env = (old.env or { }) // {
                      NIX_LDFLAGS = (old.env.NIX_LDFLAGS or "") + " -latomic";
                    };
                    meta = old.meta // {
                      platforms = (old.meta.platforms or [ ]) ++ [ "armv7l-linux" ];
                    };
                  });

              # Fix upstream Nixpkgs cross-compilation bug for Qt 6 qtdeclarative:
              # -DQt6ShaderToolsTools_DIR points to Qt6ShaderTools instead of Qt6ShaderToolsTools,
              # and missing -DQt6QuickTools_DIR causes qsb and svgtoqml to not be found,
              # which silently disabled Qt Quick on cross-compiled targets.
              qt6 = super.qt6.overrideScope (
                qfinal: qsuper: {
                  qtdeclarative = qsuper.qtdeclarative.overrideAttrs (old: {
                    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                      "-DQt6ShaderToolsTools_DIR=${final.pkgsBuildBuild.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
                      "-DQt6QuickTools_DIR=${final.pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
                    ];
                  });
                }
              );

              # Fix wuffs host gcc invocation when generating libraries during cross compilation
              wuffs = super.wuffs.overrideAttrs (old: {
                preInstall = ''
                  mkdir -p bin-compat
                  ln -sf $(type -p ${super.stdenv.cc.targetPrefix}gcc) bin-compat/gcc
                  export PATH="$PWD/bin-compat:$PATH"
                '';
              });

              # NetSurf buildsystem fails to guess BUILD in cross-compilation when host cc is not on PATH.
              # Upstream repository: https://git.netsurf-browser.org/buildsystem.git/
              netsurf-buildsystem = super.netsurf-buildsystem.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace makefiles/Makefile.tools \
                    --replace-fail 'BUILD := $(shell $(BUILD_CC) -dumpmachine)' 'BUILD ?= ${super.stdenv.buildPlatform.config}'
                '';
              });
            }
        )
      ];
    })

  ]
)
