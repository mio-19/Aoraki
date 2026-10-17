{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  kdePackages,
}:

let
  mkAsteroidApp =
    {
      name,
      owner ? "AsteroidOS",
      repo ? "asteroid-${name}",
      desc,
      rev,
      sha256,
      extraNativeBuildInputs ? [ ],
      extraBuildInputs ? [ ],
    }:
    stdenv.mkDerivation {
      pname = repo;
      version = "nightly";

      src = fetchFromGitHub {
        inherit
          owner
          repo
          rev
          sha256
          ;
      };

      nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        pkg-config
        qt6.qtdeclarative
      ]
      ++ extraNativeBuildInputs;

      buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtsvg
        qml-asteroid
      ]
      ++ extraBuildInputs;

      meta = with lib; {
        description = desc;
        homepage = "https://asteroidos.org/";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
      };
    };
in
rec {
  unofficial-watchfaces = stdenv.mkDerivation {
    pname = "asteroid-unofficial-watchfaces";
    version = "nightly";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "unofficial-watchfaces";
      rev = "2d8247c28262ba686f49a873beba4d6bff4183c1";
      sha256 = "0dg57c80dvbw9h5cnypljqshbz198wg66rap8l6qcrq3gx3f8js1";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/asteroid-launcher/watchfaces
      cp -r * $out/share/asteroid-launcher/watchfaces/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Community collection of watchfaces for AsteroidOS launcher";
      homepage = "https://github.com/AsteroidOS/unofficial-watchfaces";
      license = licenses.gpl3Plus;
      platforms = platforms.all;
    };
  };

  blaster = mkAsteroidApp {
    name = "blaster";
    owner = "eLtMosen";
    repo = "asteroid-blaster";
    desc = "Tilt-controlled asteroid shooting arcade frenzy for AsteroidOS smartwatches";
    rev = "7947938807d5de4ea7cb918b0241377aac9d3216";
    sha256 = "1vsndy01pwc333zs2c4lp4rcj4qvgmgpq0lc574h27dgkjqkphl1";
    extraBuildInputs = [
      qt6.qtsensors
      qt6.qtshadertools
    ];
  };

  dodger = mkAsteroidApp {
    name = "dodger";
    owner = "eLtMosen";
    repo = "asteroid-dodger";
    desc = "Tilt-controlled asteroid survival game for AsteroidOS smartwatches";
    rev = "9643d40db9c609a006ed89a87dc1afd907492af1";
    sha256 = "098igv2yaj3pjkiklkzmby8wlr3zmrbb8rmv0f3l1x6n56dv5096";
    extraBuildInputs = [
      qt6.qtsensors
      qt6.qtshadertools
    ];
  };

  sensorlogd = mkAsteroidApp {
    name = "sensorlogd";
    desc = "Background sensor logging daemon and QML plugin for health metrics on AsteroidOS";
    rev = "bdc9f0bb0fd6ef39f08fb01697d95cb2b98c86b6";
    sha256 = "1lb5m8g4k8sq9j9kynmffmzfj6q98rnwzbi7dr1i8fs6iq12a1ri";
    extraBuildInputs = [
      qt6.qtsensors
    ];
  };

  health = mkAsteroidApp {
    name = "health";
    desc = "Step counter, heart rate monitor, and wellness tracker for AsteroidOS";
    rev = "c85390fb9dd643f9b58e73bf698833ed7727b89f";
    sha256 = "1kk8y094sva6y3hnw0lbrk1liacpnfqknbrlv6hsry9fwgdxv3kq";
    extraBuildInputs = [
      qt6.qtsensors
      sensorlogd
    ];
  };

  map = mkAsteroidApp {
    name = "map";
    desc = "Touch and GPS map viewer for AsteroidOS smartwatches";
    rev = "8263b2175843e83c32baee2eec5380559db2b735";
    sha256 = "0f9rfbkr42fpa5f1bj3w9b8hwp1qn9v9zy7rwrjr10m1c5q64c7h";
    extraBuildInputs = [
      qt6.qtlocation
      qt6.qtpositioning
    ];
  };

  qmltester = mkAsteroidApp {
    name = "qmltester";
    owner = "MagneFire";
    repo = "asteroid-qmltester";
    desc = "Interactive developer QML viewer and testing workbench on AsteroidOS";
    rev = "b397ebfa77025ddbf093fa4cbab7d5d218cc8624";
    sha256 = "0szlc78av6d94bpzgbc0lwwf5z921b87agpjg0nw1x80asz8xwbp";
  };

  skedaddle = mkAsteroidApp {
    name = "skedaddle";
    owner = "beroset";
    repo = "asteroid-skedaddle";
    desc = "Outdoor exercise and running activity tracker with GPX recording";
    rev = "f5620c7b0c6f7ca06e2ee483ed2a0377204b6682";
    sha256 = "0v07y2fzh1zvnsnsg7b77fjpv9mq1sn4lc0k050pyf7yziy6liya";
    extraBuildInputs = [
      qt6.qtpositioning
    ];
  };

  weatherfetch = mkAsteroidApp {
    name = "weatherfetch";
    owner = "beroset";
    repo = "asteroid-weatherfetch";
    desc = "Direct internet weather forecast fetcher for AsteroidOS";
    rev = "70044bb4904d22f521fa7eb7448d5007bd863f97";
    sha256 = "04m1shcw9a36dpa5ibw5728c6d1vqiah9djlr79fq51c12sy7fvl";
  };
}
