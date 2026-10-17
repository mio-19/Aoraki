# Mode Control Entity (MCE) development headers and pkgconfig
# Upstream repository: https://github.com/sailfishos/mce-dev
# Packaging reference in AsteroidOS: https://github.com/AsteroidOS/meta-asteroid/tree/master/recipes-nemomobile/mce-dev
{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
}:

stdenv.mkDerivation rec {
  pname = "mce-dev";
  version = "nightly";

  src = fetchFromGitHub {
    owner = "sailfishos";
    repo = "mce-dev";
    rev = "5e351e2f17bba85423ee7ee13ae0d1bb10292cad";
    hash = "sha256-e1hCeZCYu9CC2w2ok2TGKXsaB72DCCnLRGoJYPR/7ZM=";
  };

  nativeBuildInputs = [ pkg-config ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include/mce $out/lib/pkgconfig
    cp -r include/mce/* $out/include/mce/
    sed -e "s|^prefix=.*|prefix=$out|" \
        -e "s|^includedir=.*|includedir=$out/include|" \
        -e "s|^Version:.*|Version: 1.33.0|" \
        mce.pc > $out/lib/pkgconfig/mce.pc
  '';

  meta = with lib; {
    description = "Mode Control Entity development headers and pkgconfig";
    homepage = "https://github.com/sailfishos/mce-dev";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
