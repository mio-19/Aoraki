{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

rec {
  wallpapers = stdenv.mkDerivation {
    pname = "asteroid-wallpapers";
    version = "2.1";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "asteroid-wallpapers";
      rev = "7e08260ed96037f3bcae1096bfc834c4755dbe93";
      sha256 = "08432b1w8naymciy88ivgjp4lb2xk5wpr4qh1iicghrbrbwfz599";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/asteroid-launcher/wallpapers
      find . -mindepth 1 -maxdepth 1 -type d -not -name ".*" -exec cp -R {} $out/share/asteroid-launcher/wallpapers/ \;
      runHook postInstall
    '';

    meta = with lib; {
      description = "Default set of wallpapers for AsteroidOS";
      homepage = "https://asteroidos.org/";
      license = licenses.cc-by-20;
      platforms = platforms.all;
    };
  };

  sounds = stdenv.mkDerivation {
    pname = "asteroid-sounds";
    version = "2.1";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "asteroid-sounds";
      rev = "8d582d135b9486e9add714cc44f0f28c7aeaa0e9";
      sha256 = "0mxppr5fcily6s5wgixa89mqpgglbjfjyvrlahyc2271rsid7zv3";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sounds/asteroid
      cp -r src/* $out/share/sounds/asteroid/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Default set of notification, alarm, and system sounds for AsteroidOS";
      homepage = "https://asteroidos.org/";
      license = licenses.cc0;
      platforms = platforms.all;
    };
  };

  icons = stdenv.mkDerivation {
    pname = "asteroid-icons-ion";
    version = "2.1";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "asteroid-icons-ion";
      rev = "7941cd491296b79941cbdad0d4b72bd34810c5dc";
      sha256 = "0l3y3cq6snvkqi93bxzcbdpg79cx3ih0728dhxklf4fz3chhx4dq";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/icons/asteroid
      cp -r src/* $out/share/icons/asteroid/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Ionicons based icon set for AsteroidOS userland";
      homepage = "https://asteroidos.org/";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  fonts = stdenv.mkDerivation {
    pname = "asteroid-fonts";
    version = "2.1";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "asteroid-fonts";
      rev = "2436c92d90385e33eccf77df22c2e5bad1b6e050";
      sha256 = "029s7cnhslb7x0vhkvb5vphj204ri62bx7az8fwk3fbd5wldsg49";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/fonts/truetype/asteroid
      find . -name "*.[to]tf" -exec install -m 0644 {} $out/share/fonts/truetype/asteroid/ \;
      runHook postInstall
    '';

    meta = with lib; {
      description = "Typography and emoji font suite for AsteroidOS smartwatches";
      homepage = "https://asteroidos.org/";
      license = licenses.ofl;
      platforms = platforms.all;
    };
  };
}
