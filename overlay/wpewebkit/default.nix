# WPE WebKit port optimized for embedded devices and smartwatches
# Upstream: https://wpewebkit.org/
# Packaging inspired by: https://github.com/eval-exec/nix-wpe-webkit
{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  perl,
  python3,
  ruby,
  bison,
  flex,
  gperf,
  gettext,
  unifdef,
  gi-docgen,
  gobject-introspection,
  libsysprof-capture,
  glib,
  libsoup_3,
  libxml2,
  libxslt,
  icu,
  harfbuzz,
  fontconfig,
  freetype,
  cairo,
  libepoxy,
  libdrm,
  libgbm,
  libinput,
  libxkbcommon,
  wayland,
  wayland-protocols,
  wayland-scanner,
  mesa,
  sqlite,
  zlib,
  libpng,
  libjpeg,
  libwebp,
  libavif,
  libjxl,
  woff2,
  lcms2,
  hyphen,
  libgcrypt,
  libgpg-error,
  libtasn1,
  p11-kit,
  pcre2,
  libseccomp,
  systemd,
  bubblewrap,
  xdg-dbus-proxy,
  at-spi2-core,
  gst_all_1,
  libwpe,
  libwpe-fdo,
  expat,
  libedit,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wpewebkit";
  version = "2.52.3";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://wpewebkit.org/releases/wpewebkit-${finalAttrs.version}.tar.xz";
    hash = "sha256-tRsdsebumdF3H0o1jBKP3ieneYTfIO5stZhY5SBmLQs=";
  };

  nativeBuildInputs = [
    bison
    cmake
    flex
    gettext
    gperf
    ninja
    perl
    pkg-config
    python3
    ruby
    unifdef
    wayland-protocols
    wayland-scanner
  ];

  buildInputs = [
    at-spi2-core
    bubblewrap
    cairo
    expat
    fontconfig
    freetype
    glib
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    icu
    (harfbuzz.override { withIcu = true; })
    hyphen
    lcms2
    libavif
    libdrm
    libedit
    libepoxy
    libgbm
    libgcrypt
    libgpg-error
    libinput
    libjpeg
    libjxl
    libpng
    libseccomp
    libsoup_3
    libtasn1
    libwebp
    libwpe
    libwpe-fdo
    libxkbcommon
    libxml2
    libxslt
    mesa
    p11-kit
    pcre2
    sqlite
    systemd
    wayland
    woff2
    xdg-dbus-proxy
    zlib
  ];

  cmakeFlags = [
    (lib.cmakeFeature "PORT" "WPE")
    (lib.cmakeBool "ENABLE_DOCUMENTATION" false)
    (lib.cmakeBool "ENABLE_INTROSPECTION" false)
    (lib.cmakeBool "ENABLE_MINIBROWSER" true)
    (lib.cmakeBool "ENABLE_SPEECH_SYNTHESIS" false)
    (lib.cmakeBool "ENABLE_VIDEO" false)
    (lib.cmakeBool "ENABLE_WEB_AUDIO" false)
    (lib.cmakeBool "ENABLE_MEDIA_STREAM" false)
    (lib.cmakeBool "ENABLE_WEB_RTC" false)
    (lib.cmakeBool "ENABLE_WPE_PLATFORM" true)
    (lib.cmakeBool "USE_LIBBACKTRACE" false)
  ];

  meta = with lib; {
    description = "WPE WebKit port optimized for embedded devices and smartwatches";
    homepage = "https://wpewebkit.org";
    license = licenses.bsd2;
    platforms = platforms.linux;
    pkgConfigModules = [ "wpe-webkit-2.0" ];
  };
})
