# Unified builder for AsteroidOS smartwatch applications
# Inspired by Nixpkgs mkKdeDerivation: https://github.com/NixOS/nixpkgs/blob/master/pkgs/kde/lib/mk-kde-derivation.nix
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  qml-asteroid,
  kdePackages,
  buildPackages,
}:

{
  name,
  pname ? "asteroid-${name}",
  version ? "nightly",
  owner ? "AsteroidOS",
  repo ? pname,
  src ? null,
  rev ? null,
  sha256 ? null,
  hash ? null,
  desc ? "Smartwatch application for AsteroidOS",
  extraNativeBuildInputs ? [ ],
  extraBuildInputs ? [ ],
  patches ? [ ],
  postPatch ? "",
  cmakeFlags ? [ ],
  meta ? { },
  ...
}:

let
  isCross = !stdenv.buildPlatform.canExecute stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version;

  src =
    if src != null then
      src
    else
      (buildPackages.fetchFromGitHub {
        inherit owner repo rev;
        ${if hash != null then "hash" else "sha256"} = if hash != null then hash else sha256;
      });

  strictDeps = true;
  inherit patches;

  postPatch = ''
    find . -name CMakeLists.txt -exec sed -i 's|/usr/share|share|g' {} +
  ''
  + postPatch;

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6.wrapQtAppsHook
    qml-asteroid
  ]
  ++ lib.optionals (!isCross) [
    qt6.qtdeclarative
    qt6.qttools
  ]
  ++ extraNativeBuildInputs;

  cmakeFlags = [
    "-DQT_MAJOR_VERSION=6"
    "-DECM_DIR=${kdePackages.extra-cmake-modules}/share/ECM/cmake"
  ]
  ++ lib.optionals isCross [
    "-DQt6QmlTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QmlTools"
    "-DQt6QuickTools_DIR=${buildPackages.qt6.qtdeclarative}/lib/cmake/Qt6QuickTools"
    "-DQt6ShaderToolsTools_DIR=${buildPackages.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools"
    "-DQt6LinguistTools_DIR=${buildPackages.qt6.qttools}/lib/cmake/Qt6LinguistTools"
  ]
  ++ cmakeFlags;

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qml-asteroid
  ]
  ++ extraBuildInputs;

  meta =
    with lib;
    {
      description = desc;
      homepage = "https://asteroidos.org/";
      license = licenses.gpl3Plus;
      mainProgram = pname;
      platforms = platforms.linux;
    }
    // meta;
})
