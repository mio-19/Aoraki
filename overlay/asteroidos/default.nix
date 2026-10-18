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

  browser = callPackage ./browser {
    inherit (pkgs) ladybird;
    netsurf = pkgs.netsurf-browser or null;
    servo = pkgs.servo or null;
    webkitgtk_6_0 = pkgs.webkitgtk_6_0 or null;
    goanna = pkgs.goanna or null;
    virtualkeyboard = assets.virtualkeyboard;
    qtvirtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
  };

  apps =
    (callPackage ./apps {
      inherit qml-asteroid;
    })
    // {
      inherit browser;
    };

  assets = callPackage ./assets { };

  community-apps = callPackage ./community-apps {
    inherit qml-asteroid;
  };

  msm-fb-refresher = callPackage ./msm-fb-refresher { };
}
