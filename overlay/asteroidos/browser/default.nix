{
  lib,
  stdenv,
  makeWrapper,
  engine ? "netsurf",
  ladybird ? null,
  netsurf ? null,
  servo ? null,
  webkitgtk_6_0 ? null,
  goanna ? null,
  virtualkeyboard ? null,
  virtualkeyboard-rime ? null,
  qtvirtualkeyboard ? null,
}:

assert lib.assertOneOf "engine" engine [
  "ladybird"
  "servo"
  "netsurf"
  "goanna"
  "webkit"
];

let
  selectedEnginePkg =
    if engine == "ladybird" then
      ladybird
    else if engine == "netsurf" then
      netsurf
    else if engine == "servo" then
      servo
    else if engine == "webkit" then
      webkitgtk_6_0
    else if engine == "goanna" then
      goanna
    else
      null;

  extraBinEnv =
    if engine == "ladybird" && ladybird != null then
      ''--set-default LADYBIRD_BIN "${ladybird}/bin/Ladybird"''
    else if engine == "netsurf" && selectedEnginePkg != null then
      ''--set-default NETSURF_BIN "${selectedEnginePkg}/bin/netsurf-gtk3"''
    else if engine == "servo" && servo != null then
      ''--set-default SERVO_BIN "${servo}/bin/servo"''
    else if engine == "webkit" && webkitgtk_6_0 != null then
      ''--set-default WEBKIT_BIN "${webkitgtk_6_0}/libexec/webkitgtk-6.0/MiniBrowser"''
    else if engine == "goanna" && goanna != null then
      ''--set-default GOANNA_BIN "${goanna}/bin/goanna"''
    else
      "";
in
# AsteroidOS smartwatch browser shell and interface abstraction with pluggable rendering backends
# Architecture inspired by AsteroidOS application suite: https://github.com/AsteroidOS
# Pluggable engine integration for Ladybird: https://github.com/LadybirdBrowser/ladybird
# NetSurf browser project: https://www.netsurf-browser.org/
# Servo parallel browser engine: https://servo.org/
stdenv.mkDerivation rec {
  pname = "asteroid-browser";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/asteroid-browser/engines
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps

    # Install main launcher with configured default engine and path substitution
    substitute asteroid-browser.sh $out/bin/asteroid-browser \
      --subst-var-by out "$out" \
      --subst-var-by defaultEngine "${engine}"
    chmod +x $out/bin/asteroid-browser

    # Install engine drivers
    install -Dm755 engines/ladybird.sh $out/share/asteroid-browser/engines/ladybird.sh
    install -Dm755 engines/netsurf.sh $out/share/asteroid-browser/engines/netsurf.sh
    install -Dm755 engines/servo.sh $out/share/asteroid-browser/engines/servo.sh
    install -Dm755 engines/webkit.sh $out/share/asteroid-browser/engines/webkit.sh
    install -Dm755 engines/goanna.sh $out/share/asteroid-browser/engines/goanna.sh

    # Install UI assets (watch portal, Qt theme, and NetSurf circular AMOLED stylesheet)
    install -Dm644 portal.html $out/share/asteroid-browser/portal.html
    install -Dm644 watch-theme.qss $out/share/asteroid-browser/watch-theme.qss
    install -Dm644 watch-round.css $out/share/asteroid-browser/watch-round.css

    # Install desktop entries
    install -Dm644 asteroid-browser.desktop $out/share/applications/asteroid-browser.desktop
    install -Dm644 asteroid-browser.desktop $out/share/applications/org.asteroidos.browser.desktop

    # Install application icons
    install -Dm644 asteroid-browser.svg $out/share/icons/hicolor/scalable/apps/asteroid-browser.svg
    install -Dm644 asteroid-browser.svg $out/share/icons/hicolor/scalable/apps/org.asteroidos.browser.svg

    # Wrap launcher with engine binaries, configured default engine, and virtual keyboard
    wrapProgram $out/bin/asteroid-browser \
      ${
        lib.optionalString (selectedEnginePkg != null)
          "--prefix PATH : ${lib.makeBinPath [ selectedEnginePkg ]}"
      } \
      --set ASTEROID_BROWSER_DEFAULT_ENGINE "${engine}" \
      ${extraBinEnv} \
      ${lib.optionalString (qtvirtualkeyboard != null) ''
        --set-default QT_IM_MODULE "qtvirtualkeyboard" \
        --set-default QT_VIRTUALKEYBOARD_STYLE "watch" \
        --prefix QT_PLUGIN_PATH : "${qtvirtualkeyboard}/lib/qt-6/plugins" \
        --prefix QML2_IMPORT_PATH : "${
          lib.optionalString (virtualkeyboard != null) "${virtualkeyboard}/lib/qml:"
        }${
          lib.optionalString (virtualkeyboard-rime != null) "${virtualkeyboard-rime}/lib/qt-6/qml:"
        }${qtvirtualkeyboard}/lib/qt-6/qml" \
        ${lib.optionalString (virtualkeyboard-rime != null) ''
          --set-default QT_VIRTUALKEYBOARD_LAYOUT_PATH "${virtualkeyboard-rime}/share/qtvirtualkeyboard/layouts" \
          --set-default RIME_SHARED_DATA_DIR "${virtualkeyboard-rime}/share/rime-data" \
        ''}
      ''}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Smartwatch web browser interface for AsteroidOS with build-time pluggable engine selection";
    homepage = "https://asteroidos.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "asteroid-browser";
  };
}
