# AsteroidOS smartwatch browser powered by WebKitGTK 6.0
# Architecture inspired by AsteroidOS application suite: https://asteroidos.org/
{
  lib,
  stdenv,
  pkg-config,
  makeWrapper,
  gtk4,
  webkitgtk_6_0,
}:

stdenv.mkDerivation {
  pname = "asteroid-browser";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    gtk4
    webkitgtk_6_0
  ];

  buildPhase = ''
    runHook preBuild

    $CC -O2 src/main.c \
      $(pkg-config --cflags --libs gtk4 webkitgtk-6.0) \
      -o asteroid-browser

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/asteroid-browser
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps

    # Install compiled binary
    install -Dm755 asteroid-browser $out/bin/asteroid-browser

    # Install UI assets (watch portal and GTK watch theme)
    install -Dm644 portal.html $out/share/asteroid-browser/portal.html
    install -Dm644 watch-gtk.css $out/share/asteroid-browser/watch-gtk.css

    # Install desktop entries
    install -Dm644 asteroid-browser.desktop $out/share/applications/asteroid-browser.desktop
    install -Dm644 asteroid-browser.desktop $out/share/applications/org.asteroidos.browser.desktop

    # Install application icons
    install -Dm644 asteroid-browser.svg $out/share/icons/hicolor/scalable/apps/asteroid-browser.svg
    install -Dm644 asteroid-browser.svg $out/share/icons/hicolor/scalable/apps/org.asteroidos.browser.svg

    # Wrap binary with Wayland display environment and resource paths
    wrapProgram $out/bin/asteroid-browser \
      --set-default GDK_BACKEND "wayland" \
      --set-default WEBKIT_FORCE_SANDBOX "0" \
      --set-default ASTEROID_BROWSER_SHARE "$out/share/asteroid-browser"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Smartwatch web browser interface for AsteroidOS powered by WebKitGTK 6.0";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "asteroid-browser";
  };
}
