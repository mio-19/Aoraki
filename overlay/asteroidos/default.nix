{ callPackage, pkgs }:

rec {
  mkAsteroidApp = callPackage ./lib/mk-asteroid-app.nix {
    inherit qml-asteroid;
  };

  qml-asteroid = callPackage ./qml-asteroid { };

  asteroid-launcher = callPackage ./asteroid-launcher {
    inherit
      qml-asteroid
      mlite
      mce-dev
      mce-qt6
      ngf-qt6
      usb-moded-qt6
      keepalive
      timed-qt6
      ;
  };

  amber-mpris = callPackage ./amber-mpris { };
  mlite = callPackage ./mlite { };
  mce-dev = callPackage ./mce-dev { };
  mce-qt6 = callPackage ./mce-qt6 {
    inherit mce-dev;
  };
  ngf-qt6 = callPackage ./ngf-qt6 { };
  usb-moded-qt6 = callPackage ./usb-moded-qt6 { };
  keepalive = callPackage ./keepalive { };
  timed-qt6 = callPackage ./timed-qt6 { };

  asteroid-btsyncd = callPackage ./asteroid-btsyncd {
    inherit qml-asteroid amber-mpris mlite;
  };

  browser = callPackage ./browser {
    inherit qml-asteroid;
    virtualkeyboard = assets.virtualkeyboard;
    inherit virtualkeyboard-rime;
    qtvirtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
  };

  telegram = callPackage ./telegram {
    inherit qml-asteroid;
  };

  kiwix = callPackage ./kiwix {
    kiwix-tools = pkgs.kiwix-tools;
    inherit browser;
    inherit (pkgs) procps;
  };

  ytmusicd = callPackage ./ytmusicd { };

  apps =
    (callPackage ./apps {
      inherit mkAsteroidApp mce-dev ngf-qt6;
    })
    // {
      inherit browser telegram kiwix;
    };

  assets = (callPackage ./assets { }) // {
    inherit virtualkeyboard-rime;
  };

  virtualkeyboard-rime = callPackage ./virtualkeyboard-rime { };

  community-apps = callPackage ./community-apps {
    inherit mkAsteroidApp mlite;
    inherit (pkgs) espeak-classic;
  };

  msm-fb-refresher = callPackage ./msm-fb-refresher { };
}
