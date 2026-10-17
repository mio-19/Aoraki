{ callPackage, pkgs }:

rec {
  qml-asteroid = callPackage ./qml-asteroid { };

  asteroid-launcher = callPackage ./asteroid-launcher {
    inherit qml-asteroid;
  };

  amber-mpris = callPackage ./amber-mpris { };
  mlite = callPackage ./mlite { };

  asteroid-btsyncd = callPackage ./asteroid-btsyncd {
    inherit qml-asteroid amber-mpris mlite;
  };

  apps = callPackage ./apps {
    inherit qml-asteroid;
  };

  assets = callPackage ./assets { };

  community-apps = callPackage ./community-apps {
    inherit qml-asteroid;
  };

  msm-fb-refresher = callPackage ./msm-fb-refresher { };
}
