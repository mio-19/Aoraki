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
      desc,
      rev,
      sha256,
      extraBuildInputs ? [ ],
    }:
    stdenv.mkDerivation {
      pname = "asteroid-${name}";
      version = "nightly";

      src = fetchFromGitHub {
        owner = "AsteroidOS";
        repo = "asteroid-${name}";
        inherit rev sha256;
      };

      nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        pkg-config
        qt6.qtdeclarative
        qt6.wrapQtAppsHook
      ];

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
{
  stopwatch = mkAsteroidApp {
    name = "stopwatch";
    desc = "Smartwatch stopwatch application for AsteroidOS";
    rev = "a07d0a6f30bd343c48b1554fdba606873e708c8a";
    sha256 = "1xn7lnvzgwlp8vwq955c1d4hb303yddwhp0c6nip7lbxklv4la37";
  };

  timer = mkAsteroidApp {
    name = "timer";
    desc = "Countdown timer application with vibration alert";
    rev = "28d3fa8a664c3f8a03ec463fe8de648b4fbc34cc";
    sha256 = "13gsd44spnqrz42f5cafdc7nbqdgzhr0bjbvz9rzw9x06d9gq1gb";
  };

  alarmclock = mkAsteroidApp {
    name = "alarmclock";
    desc = "Wake-up alarm application for AsteroidOS";
    rev = "e0e457442380edb4877a5aef224d156a1ca8b0a5";
    sha256 = "1czb184a2y3h1qcfg2pfcs5pd01h4pmh7zg2p262rzxgvpv4vgg8";
  };

  calculator = mkAsteroidApp {
    name = "calculator";
    desc = "Touch calculator designed for round & square smartwatch displays";
    rev = "ca3241af839df6011b8e91d452cdef1e0c64fb98";
    sha256 = "1a00zc5yav10fl462hwzbb2rc3dm755l527yhr7ya4dhz114lh4l";
  };

  settings = mkAsteroidApp {
    name = "settings";
    desc = "Smartwatch preferences and configuration application";
    rev = "60340bd1c27a7b9e4884bd61c0563d091bc8b240";
    sha256 = "13iax0c449wsb24a945xaqi5g9jshng244sfiiy191ag6q2gp6p2";
  };

  weather = mkAsteroidApp {
    name = "weather";
    desc = "Weather forecast application synchronized via Bluetooth";
    rev = "f42f0706de13205d1f9486414158474ad426f18c";
    sha256 = "14f8yv7hh9hzrhs9m40jqxsy2nmz4aggfvb4xygzfxvqihl5pzmf";
  };

  music = mkAsteroidApp {
    name = "music";
    desc = "Media playback remote controller for phone media players";
    rev = "1087453140957314ef7ce20bb79250dd2509dd35";
    sha256 = "03cjxcy47292svjgx62hf5ri99bbcbgxxfmrf6f304gyzsf98dd6";
  };

  compass = mkAsteroidApp {
    name = "compass";
    desc = "Sensor-driven compass application for smartwatches";
    rev = "7d3151cfd9a54856850c7cd9a6e33476221cb302";
    sha256 = "0qv30gh2p9d2zyy79khf842wdi1wqyjk7amhwas65a69lhy0p7zq";
  };

  flashlight = mkAsteroidApp {
    name = "flashlight";
    desc = "Full-screen high-brightness torch utility";
    rev = "ca7788d84eb08da40b0b7a59ea6e11ae95c72f1c";
    sha256 = "0a7vvnvrqmy24zb4vclp2gljzjdbqxsk5i50y7284ci3vqbzw7yl";
  };

  calendar = mkAsteroidApp {
    name = "calendar";
    desc = "Smartwatch calendar and agenda viewer for AsteroidOS";
    rev = "02b78a66bb2c317212506f87197717b817e12afa";
    sha256 = "00ivicf28276msql3ga8n2ahxkia7g0m1g3a05chahiryw3gbwab";
  };

  diamonds = mkAsteroidApp {
    name = "diamonds";
    desc = "2048-like puzzle game designed for smartwatches";
    rev = "fc80087960e8db2b0a8513b8830bdb32ec2a3872";
    sha256 = "0qvjkkf4g4fy0l0bxmwxlxp3wjw82drrwvgbwdbxrk1gynx35bcz";
  };

  hrm = mkAsteroidApp {
    name = "hrm";
    desc = "Heart rate monitor application using optical sensors";
    rev = "0b96ceba07237f2a8a738b58fb80dff2265cf2c4";
    sha256 = "0nhrz5hrqgcdpk6p40rnv0dgxpah83kpr6k6qv3kh0df5nnmwk84";
  };

  camera = mkAsteroidApp {
    name = "camera";
    desc = "Remote phone camera shutter and preview controller";
    rev = "53c3e636a4f71b05950d125b622cfd8876985fc9";
    sha256 = "0b0vkjh31hjmn5fxvcan5d75xn6ajfslp35hxm7a19g2v5vmij4z";
  };

  gps-test = mkAsteroidApp {
    name = "gps-test";
    desc = "GNSS satellite fix, location coordinates, and velocity tester";
    rev = "991329e453854593094cea018f6412f7e2e654bd";
    sha256 = "0k40pvvd9nhsj228zydajk97vasfkn3cjvn1xp2j86j7y9ica2pc";
  };
}
