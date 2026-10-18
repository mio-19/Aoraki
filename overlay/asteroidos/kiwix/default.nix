{
  lib,
  stdenv,
  makeWrapper,
  kiwix-tools,
  browser,
  procps,
}:

# Kiwix offline Wikipedia and reference reader adaptation for smartwatches
# Upstream desktop reference: https://github.com/kiwix/kiwix-desktop
# Upstream tools & serve backend: https://github.com/kiwix/kiwix-tools
stdenv.mkDerivation {
  pname = "asteroid-kiwix";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/kiwix-watch
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps

    # Install launcher script with substitution
    substitute kiwix-watch.sh $out/bin/kiwix-watch \
      --subst-var-by out "$out"
    chmod +x $out/bin/kiwix-watch

    # Install UI assets
    install -Dm644 welcome.html $out/share/kiwix-watch/welcome.html

    # Install desktop entry
    install -Dm644 org.kiwix.desktop.desktop $out/share/applications/org.kiwix.desktop.desktop
    install -Dm644 org.kiwix.desktop.desktop $out/share/applications/kiwix.desktop

    # Install icon
    install -Dm644 kiwix.svg $out/share/icons/hicolor/scalable/apps/kiwix.svg
    install -Dm644 kiwix.svg $out/share/icons/hicolor/scalable/apps/org.kiwix.desktop.svg

    # Wrap launcher with kiwix-tools, asteroid-browser, and process management
    wrapProgram $out/bin/kiwix-watch \
      --prefix PATH : ${
        lib.makeBinPath [
          kiwix-tools
          browser
          procps
        ]
      } \
      --set-default KIWIX_WATCH_SHARE "$out/share/kiwix-watch"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Offline Wikipedia and reference reader adapted for smartwatches using kiwix-tools and asteroid-browser";
    homepage = "https://www.kiwix.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "kiwix-watch";
  };
}
