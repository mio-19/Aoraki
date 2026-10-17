{ callPackage, pkgs }:

rec {
  qml-asteroid = callPackage ./qml-asteroid { };

  asteroid-launcher = callPackage ./asteroid-launcher {
    inherit qml-asteroid;
  };

  asteroid-btsyncd = callPackage ./asteroid-btsyncd { };

  apps = callPackage ./apps {
    inherit qml-asteroid;
  };

  assets = callPackage ./assets { };
}
