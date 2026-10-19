final: super:

let
  callPackage = final.callPackage;
in
{
  # Misc. tools.
  # Keep sorted.
  adbd = callPackage ./adbd { };
  android-headers = callPackage ./android-headers { };
  asteroid = import ./asteroidos {
    inherit callPackage;
    pkgs = final;
  };
  dtbTool = callPackage ./dtbtool { };
  dtbTool-exynos = callPackage ./dtbtool-exynos { };
  libhybris = callPackage ./libhybris { };
  mkbootimg = callPackage ./mkbootimg { };
  msm-fb-refresher = callPackage ./msm-fb-refresher { };
  ply-image = callPackage ./ply-image { };
  qc-image-unpacker = callPackage ./qc-image-unpacker { };
  ufdt-apply-overlay = callPackage ./ufdt-apply-overlay { };

  # Extra "libs"
  mkExtraUtils = import ./lib/extra-utils.nix {
    inherit (final)
      runCommandCC
      glibc
      buildPackages
      ;
    inherit (final.buildPackages)
      nukeReferences
      ;
  };

  #
  # New software to upstream
  # ------------------------
  #

  android-partition-tools = callPackage ./android-partition-tools {
    stdenv = with final; overrideCC stdenv buildPackages.clang;
  };
  make_ext4fs = callPackage ./make_ext4fs { };
  hardshutdown = callPackage ./hardshutdown { };
  bootlogd = callPackage ./bootlogd { };
  libusbgx = callPackage ./libusbgx { };
  gadget-tool = callPackage ./gt { }; # upstream this is called "gt", which is very Unix.

  qrtr = callPackage ./qrtr/qrtr.nix { };
  qmic = callPackage ./qrtr/qmic.nix { };
  tqftpserv = callPackage ./qrtr/tqftpserv.nix { };
  pd-mapper = callPackage ./qrtr/pd-mapper.nix { };
  rmtfs = callPackage ./qrtr/rmtfs.nix { };

  #
  # Hacks
  # -----
  #
  # Totally not upstreamable stuff.
  #

  xf86-video-fbdev = super.xf86-video-fbdev.overrideAttrs (
    {
      patches ? [ ],
      ...
    }:
    {
      patches = patches ++ [
        ./xserver/0001-HACK-fbdev-don-t-bail-on-mode-initialization-fail.patch
      ];
    }
  );

  #
  # Fixes to upstream
  # -----------------
  #
  # Upstream nixpkgs Qt6 modules skip QtQuick integration during cross-compilation
  # because cross Qt6QuickTools, Qt6QmlTools, and Qt6ShaderToolsTools cmake flags are missing.
  qt6 = super.qt6.overrideScope (
    qfinal: qsuper:
    let
      isCross = !final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform;
      addCrossQuickTools =
        pkg:
        pkg.overrideAttrs (
          old:
          final.lib.optionalAttrs isCross {
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [
              "-DQt6QuickTools_DIR=${final.buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
              "-DQt6QmlTools_DIR=${final.buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
              "-DQt6ShaderToolsTools_DIR=${final.buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
            ];
          }
        );
    in
    {
      qtdeclarative = qsuper.qtdeclarative.overrideAttrs (
        old:
        final.lib.optionalAttrs isCross {
          cmakeFlags =
            (map (
              flag:
              if final.lib.hasPrefix "-DQt6ShaderToolsTools_DIR=" flag then
                "-DQt6ShaderToolsTools_DIR=${final.pkgsBuildBuild.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
              else
                flag
            ) (old.cmakeFlags or [ ]))
            ++ [
              "-DQt6QuickTools_DIR=${final.pkgsBuildBuild.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
            ];
        }
      );
      qtwayland = addCrossQuickTools qsuper.qtwayland;
      qtvirtualkeyboard = addCrossQuickTools qsuper.qtvirtualkeyboard;
      qtmultimedia = addCrossQuickTools qsuper.qtmultimedia;
      qtpositioning = addCrossQuickTools qsuper.qtpositioning;
      qtsensors = addCrossQuickTools qsuper.qtsensors;
      qtconnectivity = addCrossQuickTools qsuper.qtconnectivity;
      qtquick3d = qsuper.qtquick3d.overrideAttrs (
        old:
        final.lib.optionalAttrs isCross {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DQt6QuickTools_DIR=${final.buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
            "-DQt6QmlTools_DIR=${final.buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
            "-DQt6ShaderToolsTools_DIR=${final.buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
            "-DQt6Quick3DTools_DIR=${final.buildPackages.qt6.qtquick3d}/lib/cmake/Qt6Quick3DTools"
          ];
        }
      );
      qtlocation = addCrossQuickTools qsuper.qtlocation;
    }
  );

  # Things specific to mobile-nixos.
  # Not necessarily internals, but they probably won't go into <nixpkgs>.
  mobile-nixos = {
    kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix { };
    kernel-builder-clang = callPackage ./mobile-nixos/kernel/builder.nix {
      stdenv = with final; overrideCC stdenv buildPackages.clang;
    };

    # Compatibility aliases for the versioned kernel builders dropped by
    # eb31ee50 ("kernel-builder: Drop versioned builders").
    #
    # The vendor-based Android devices under `devices/` still refer to these
    # names. The pinned Nixpkgs no longer provides gcc49/gcc6/clang_8/clang_9,
    # so these aliases intentionally fall back to the default compilers.
    #
    # This keeps those device configurations evaluable, which is what CI
    # checks (.ci/parse-all.sh and .ci/quick-eval.sh). It does **not** make
    # them buildable: these old out-of-tree kernels need their original
    # compiler vintage and fail during compilation.
    kernel-builder-gcc49 = callPackage ./mobile-nixos/kernel/builder.nix { };
    kernel-builder-gcc6 = callPackage ./mobile-nixos/kernel/builder.nix {
      stdenv = with final; overrideCC stdenv buildPackages.gcc;
    };
    kernel-builder-clang_8 = callPackage ./mobile-nixos/kernel/builder.nix {
      stdenv = with final; overrideCC stdenv buildPackages.clang;
    };
    kernel-builder-clang_9 = callPackage ./mobile-nixos/kernel/builder.nix {
      stdenv = with final; overrideCC stdenv buildPackages.clang;
    };

    # We need to "globally" locally override some packages for stage-1.
    stage-1 = (final.appendOverlays [ (import ../boot/overlay) ]).mobile-nixos.stage-1;

    # Originally part of `stage-1`.
    # In stage-1 it is now overridden with the cut-down libinput and libxkbcommon.
    script-loader = callPackage ../boot/script-loader { };

    # Flashable zip binaries are always static.
    android-flashable-zip-binaries =
      final.pkgsStatic.callPackage ./mobile-nixos/android-flashable-zip-binaries
        { };

    autoport = callPackage ./mobile-nixos/autoport { };

    boot-control = callPackage ./mobile-nixos/boot-control { };

    boot-recovery-menu-simulator = final.mobile-nixos.stage-1.boot-recovery-menu.simulator;
    boot-splash-simulator = final.mobile-nixos.stage-1.boot-splash.simulator;

    fdt-forward = callPackage ./mobile-nixos/fdt-forward { };

    gui-assets = callPackage ./mobile-nixos/gui-assets { };

    make-flashable-zip = callPackage ./mobile-nixos/android-flashable-zip/make-flashable-zip.nix { };

    map-dtbs = callPackage ./mobile-nixos/map-dtbs { };

    mkLVGUIApp = callPackage ./mobile-nixos/lvgui { };

    cross-canary-test = callPackage ./mobile-nixos/cross-canary/test.nix { };
    cross-canary-test-static = final.pkgsStatic.callPackage ./mobile-nixos/cross-canary/test.nix { };
  };

  image-builder = callPackage ./image-builder { };
}
