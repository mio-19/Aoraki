{
  mobile-nixos,
  fetchFromGitLab,
  fetchurl,
  runCommand,
  ...
}:

# Google Pixel Watch 2 (aurora) runs an Android 13 downstream 5.15 GKI kernel.
# Upstream UBPorts kernel source:
# gitlab.com/ubports/porting/community-ports/android13/google-eos/kernel-for-google-eos.git (branch halium-13.0)
let
  src = fetchFromGitLab {
    owner = "ubports/porting/community-ports/android13/google-eos";
    repo = "kernel-for-google-eos";
    rev = "063840c5aae117bf0faac8b34fba0e37c9f619f8";
    sha256 = "0bicl1n5sqglffz31vf1092c31ygwx8achqw6zbc8wsx8pfz5aig";
  };

  # Upstream AsteroidOS kernel configuration fragment:
  # https://github.com/AsteroidOS/meta-smartwatch/blob/master/meta-aurora/recipes-kernel/linux/linux-aurora/sw5100.fragment
  sw5100Fragment = fetchurl {
    url = "https://raw.githubusercontent.com/AsteroidOS/meta-smartwatch/master/meta-aurora/recipes-kernel/linux/linux-aurora/sw5100.fragment";
    sha256 = "1p36ngv64dc1q1qjswmzxb9yzj3bx75rv2zg1gk1jfla0hp5cslm";
  };

  # Generate defconfig matching AsteroidOS linux-aurora_5.15.144.bb:
  # merge_config.sh gki_defconfig + monaco_GKI.config + sw5100.fragment
  configfile = runCommand "google-aurora-defconfig" { } ''
    sh ${src}/scripts/kconfig/merge_config.sh -m -r -O . \
      ${src}/arch/arm64/configs/gki_defconfig \
      ${src}/arch/arm64/configs/vendor/monaco_GKI.config \
      ${sw5100Fragment}
    echo "# CONFIG_DEBUG_INFO_BTF is not set" >> .config
    cp .config $out
  '';
in
mobile-nixos.kernel-builder {
  version = "5.15.144";
  inherit configfile src;

  patches = [
    ./0001-video-fbdev-add-qcom-continuous-splash-framebuffer.patch
    ./cc-o-c-respfile.patch
    ./cmd-mod-file-func.patch
    ./eud-secure-fail-nonfatal.patch
    ./modfinal-cc-o-c-respfile.patch
    ./rtc-pm8xxx-read-only.patch
  ];

  isModular = true;
}
