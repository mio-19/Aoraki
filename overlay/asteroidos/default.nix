{ callPackage, pkgs }:

rec {
  mkAsteroidApp = callPackage ./lib/mk-asteroid-app.nix {
    inherit qml-asteroid;
  };

  qml-asteroid = callPackage ./qml-asteroid { };

  asteroid-launcher = callPackage ./asteroid-launcher {
    inherit qml-asteroid;
  };

  amber-mpris = callPackage ./amber-mpris { };
  mlite = callPackage ./mlite { };

  asteroid-btsyncd = callPackage ./asteroid-btsyncd {
    inherit qml-asteroid amber-mpris mlite;
  };

  browser = callPackage ./browser {
    inherit (pkgs) ladybird;
    netsurf = pkgs.netsurf-browser or null;
    servo = pkgs.servo or null;
    webkitgtk_6_0 = pkgs.webkitgtk_6_0 or null;
    goanna = pkgs.goanna or null;
    virtualkeyboard = assets.virtualkeyboard;
    inherit virtualkeyboard-rime;
    qtvirtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
  };

  telegram = callPackage ./telegram {
    inherit qml-asteroid;
  };

  apps =
    (callPackage ./apps {
      inherit mkAsteroidApp;
    })
    // {
      inherit browser telegram;
    };

  assets = (callPackage ./assets { }) // {
    inherit virtualkeyboard-rime;
  };

  virtualkeyboard-rime = callPackage ./virtualkeyboard-rime { };

  community-apps = callPackage ./community-apps {
    inherit mkAsteroidApp;
  };

  msm-fb-refresher = callPackage ./msm-fb-refresher { };
}
