{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "msm-fb-refresher";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "AsteroidOS";
    repo = "msm-fb-refresher";
    rev = "b89cca860f9c37e71b3fbd5ae53c4e8d521e1de8";
    sha256 = "0q8wlyb9aab2k4zqapg6l7y01h5fcbb6ggq9y6w0gp7h1d8rm2pc";
  };

  buildPhase = ''
    runHook preBuild
    $CC refresher.c -o msm-fb-refresher
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 msm-fb-refresher $out/bin/msm-fb-refresher
    runHook postInstall
  '';

  meta = with lib; {
    description = "Refreshes Qualcomm framebuffer ioctl on boot for early display wakeup";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
