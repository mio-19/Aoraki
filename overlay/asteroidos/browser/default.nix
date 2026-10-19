# AsteroidOS native smartwatch web browser
# Real WebKit browser engine (WebKitGTK 6.0) optimized for wearable displays
# Upstream architecture: https://asteroidos.org/
{
  lib,
  stdenv,
  cmake,
  pkg-config,
  webkitgtk_6_0,
  gtk4,
  wrapGAppsHook4,
  glib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asteroid-browser";
  version = "1.0.0";

  src = ./.;

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    webkitgtk_6_0
    gtk4
    glib
  ];

  dontWrapGApps = false;

  meta = with lib; {
    description = "Native WebKit smartwatch browser for AsteroidOS";
    homepage = "https://asteroidos.org";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "asteroid-browser";
  };
})
