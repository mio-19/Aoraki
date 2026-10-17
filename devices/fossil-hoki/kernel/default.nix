{
  mobile-nixos,
  stdenv,
  cpio,
  fetchFromGitHub,
  ...
}:

# Fossil Gen 6 (hoki) ships a 4.14 downstream Qualcomm kernel.
# Upstream source tree: https://github.com/fossil-engineering/kernel-msm-fossil-cw
# AsteroidOS recipe: https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-hoki/recipes-kernel/linux/linux-hoki_p.bb
#
# It must be built with GCC 8: AsteroidOS's recipe inherits `kernel-gcc8` (https://github.com/AsteroidOS/meta-asteroid/blob/master/classes/kernel-gcc8.bbclass)
# and notes "gcc >= 13 doesn't boot". Nixpkgs dropped gcc8, so borrow the armv7l
# cross compiler from nixos-24.05 (the last channel still shipping 8.5.0).
#
# Patches 0001-0006 are vendored verbatim from AsteroidOS meta-smartwatch:
# https://github.com/AsteroidOS/meta-smartwatch/tree/master/meta-hoki/recipes-kernel/linux/files
# Patch 0007 fixes unconditional pm_qos_remove_request crash in pcm_native.c:
# https://github.com/AsteroidOS/meta-smartwatch/pull/344
# 90_dtbs-install is ours: this tree has no ARM dtbs_install target.
let
  # Pinned by git rev rather than a channel URL: channels.nixos.org/nixos-24.05
  # is a moving target whose NAR hash changes as the branch advances, and that
  # branch is gone now that 24.05 is EOL.
  pkgsGcc8 = import (builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    rev = "b134951a4c9f3c995fd7be05f3243f8ecd65d798";
    shallow = true;
  }) { };

  cc8 = pkgsGcc8.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc8;

  # Same as pkgs.overrideCC (pkgs/stdenv/adapters.nix), inlined so this file
  # does not need the surrounding package set.
  stdenvGcc8 = stdenv.override {
    allowedRequisites = null;
    cc = cc8;
    hasCC = true;
  };

  kernel-builder-gcc8 = mobile-nixos.kernel-builder.override {
    stdenv = stdenvGcc8;
  };
in

kernel-builder-gcc8 {
  version = "4.14.206";
  configfile = ./config.armv7;

  src = fetchFromGitHub {
    owner = "fossil-engineering";
    repo = "kernel-msm-fossil-cw";
    rev = "c0b4c201f2d5a641defe19958a9b4c16f40d866b";
    sha256 = "sha256-uf5Vln2M64ksT9BC4/R9gLV2yo6zK0vQeolyCUj/u+o=";
  };

  patches = [
    ./0001-dts-Add-hoki-device-trees.patch
    ./0002-mmc-Fix-embedded_sdio_data-duplicate-definition.patch
    ./0003-video-fbdev-msm-Provide-mdss_dsi_switch_page.patch
    ./0004-usb-hcd-Handle-when-host-mode-isn-t-available.patch
    ./0005-initramfs-Don-t-skip-initramfs.patch
    ./0006-ARM-8933-1-replace-Sun-Solaris-style-flag-on-section.patch
    ./0007-pcm_native-guard-pm_qos_remove_request-with-active-.patch
    ./90_dtbs-install.patch
  ];

  isModular = false;

  # Qualcomm backported the 5.3 kheaders feature into this 4.14 tree
  # (CONFIG_IKHEADERS=y), and kernel/gen_kheaders.sh needs cpio. The builder
  # only supplies cpio for >= 5.2, so add it here.
  nativeBuildInputs = [ cpio ];

  # Set by CONFIG_BUILD_ARM_APPENDED_DTB_IMAGE in the defconfig.
  buildDTBs = true;
}
