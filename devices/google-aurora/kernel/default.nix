{
  mobile-nixos,
  fetchFromGitLab,
  ...
}:

# Google Pixel Watch 2 (aurora) runs an Android 13 downstream 5.15 GKI kernel.
# Upstream UBPorts kernel source:
# gitlab.com/ubports/porting/community-ports/android13/google-eos/kernel-for-google-eos.git (branch halium-13.0)
mobile-nixos.kernel-builder {
  version = "5.15.144";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "ubports/porting/community-ports/android13/google-eos";
    repo = "kernel-for-google-eos";
    rev = "063840c5aae117bf0faac8b34fba0e37c9f619f8";
    sha256 = "0bicl1n5sqglffz31vf1092c31ygwx8achqw6zbc8wsx8pfz5aig";
  };

  isModular = false;
}
