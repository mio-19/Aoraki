# Standalone YouTube Music stream resolver daemon for smartwatches
# Inspired by yt-dlp media extraction in mobile media clients: https://github.com/yt-dlp/yt-dlp
{
  lib,
  stdenv,
  python3,
  makeWrapper,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.yt-dlp
  ]);
in
stdenv.mkDerivation {
  pname = "asteroid-ytmusicd";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib/asteroid-ytmusicd
    install -m 755 asteroid-ytmusicd.py $out/lib/asteroid-ytmusicd/asteroid-ytmusicd.py
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/asteroid-ytmusicd \
      --add-flags "$out/lib/asteroid-ytmusicd/asteroid-ytmusicd.py"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Standalone YouTube Music stream resolver daemon for smartwatches";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
