{ lib
, stdenv
, fetchFromGitHub
, cmake
, extra-cmake-modules
, pkg-config
, qt5
, qml-asteroid
}:

let
  mkAsteroidApp = { name, desc, sha256 }: stdenv.mkDerivation rec {
    pname = "asteroid-${name}";
    version = "2.1";

    src = fetchFromGitHub {
      owner = "AsteroidOS";
      repo = "asteroid-${name}";
      rev = version;
      inherit sha256;
    };

    nativeBuildInputs = [
      cmake
      extra-cmake-modules
      pkg-config
    ];

    buildInputs = [
      qt5.qtbase
      qt5.qtdeclarative
      qt5.qtquickcontrols
      qml-asteroid
    ];

    meta = with lib; {
      description = desc;
      homepage = "https://asteroidos.org/";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
    };
  };
in
{
  stopwatch = mkAsteroidApp {
    name = "stopwatch";
    desc = "Smartwatch stopwatch application for AsteroidOS";
    sha256 = "0q3cs4y9fa750spn2ncjcs73fx3m8vnnh7vc68cq8zi815cddlqa";
  };

  timer = mkAsteroidApp {
    name = "timer";
    desc = "Countdown timer application with vibration alert";
    sha256 = "177lzskglwlj7m8kdzx8q3dh0sb4bllm58hq3wa9aspifcarf0xj";
  };

  alarmclock = mkAsteroidApp {
    name = "alarmclock";
    desc = "Wake-up alarm application for AsteroidOS";
    sha256 = "01rysac2mmzgwr088babkqbnh1jxrfbkc9d3g4hnyj94wx6j8fan";
  };

  calculator = mkAsteroidApp {
    name = "calculator";
    desc = "Touch calculator designed for round & square smartwatch displays";
    sha256 = "0x13df52rn1f2yam0hlxfhh1v3vilsi004km0xj48kxxbqj105v7";
  };

  settings = mkAsteroidApp {
    name = "settings";
    desc = "Smartwatch preferences and configuration application";
    sha256 = "0fq2g57yjcbw4b7y7b9h20kld1xizgzslbiyiqnff1ri3b0hchzs";
  };

  weather = mkAsteroidApp {
    name = "weather";
    desc = "Weather forecast application synchronized via Bluetooth";
    sha256 = "172ld7w9y2wlb0w7a70l9k6y2n3frny399941vw7ivbwfhharvjg";
  };

  music = mkAsteroidApp {
    name = "music";
    desc = "Media playback remote controller for phone media players";
    sha256 = "001ssza3n523g18pl2aclqa6gfsh5qv3a2van92p1q89scac1xaj";
  };

  compass = mkAsteroidApp {
    name = "compass";
    desc = "Sensor-driven compass application for smartwatches";
    sha256 = "0lgpaa1mag6pr8h61xihv93804s6yib3sh5f922wgv4z4admjgjx";
  };

  flashlight = mkAsteroidApp {
    name = "flashlight";
    desc = "Full-screen high-brightness torch utility";
    sha256 = "19zbdmn7amzawam543brp93k4f8jdx1p2xr710vhskf1wynl7khm";
  };
}
