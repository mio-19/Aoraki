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
    inherit virtualkeyboard;
    qtvirtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
  };

  telegram = callPackage ./telegram {
    inherit qml-asteroid;
    inherit virtualkeyboard;
    qtvirtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
    tdlib = if pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform then pkgs.tdlib else null;
  };

  kiwix = callPackage ./kiwix {
    kiwix-tools = pkgs.kiwix-tools;
    inherit browser;
    inherit (pkgs) procps;
  };

  apps =
    (callPackage ./apps {
      inherit mkAsteroidApp mce-dev ngf-qt6;
    })
    // {
      inherit browser telegram kiwix;
    };

  assets = (callPackage ./assets { }) // {
    inherit virtualkeyboard;
  };

  virtualkeyboard = callPackage ./virtualkeyboard { };

  community-apps = callPackage ./community-apps {
    inherit mkAsteroidApp mlite;
    inherit (pkgs) espeak-classic;
  };

  msm-fb-refresher = callPackage ./msm-fb-refresher { };
}
