{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  zstd,
  makeWrapper,
  libglvnd,
  fontconfig,
  freetype,
  libxkbcommon,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxshmfence,
  mesa,
  libdrm,
  libpulseaudio,
  alsa-lib,
  dbus,
  glib,
  nss,
  nspr,
  cups,
  systemd,
  libbsd,
  icu,
  libkrb5,
  pcre,
  libpng,
  libcap,
  brotli,
  lz4,
  xz,
  libmd,
  wayland,
  e2fsprogs,
  qt6,
}:

stdenv.mkDerivation rec {
  pname = "happ-desktop";
  version = "2.14.0";

  src = fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "sha256-1OFkT2lAr7ETlnFhYQqE2rEOVKED0va/3lD4LQchMQo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    zstd
    makeWrapper
  ];

  buildInputs = [
    libglvnd
    fontconfig
    freetype
    libxkbcommon
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    mesa
    libdrm
    libpulseaudio
    alsa-lib
    dbus
    glib
    nss
    nspr
    cups
    systemd
    libbsd
    icu
    libkrb5
    pcre
    libpng
    libcap
    brotli
    lz4
    xz
    zstd
    libmd
    wayland
    e2fsprogs
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
  ];

  dontWrapQtApps = true;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
        mkdir -p $out
        cp -r opt $out/

        # Desktop entry
        mkdir -p $out/share/applications
        cat > $out/share/applications/happ.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Happ
    Exec=$out/bin/Happ %f
    Icon=happ
    MimeType=application/x-happ;application/json;
    Categories=Utility;Network;
    Terminal=false
    EOF

        # Icon
        mkdir -p $out/share/icons/hicolor/256x256/apps
        cp usr/share/icons/hicolor/256x256/apps/happ.png $out/share/icons/hicolor/256x256/apps/

        # Binaries
        mkdir -p $out/bin
        makeWrapper $out/opt/happ/bin/Happ $out/bin/Happ \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}:$out/opt/happ/lib" \
          --set QT_PLUGIN_PATH "$out/opt/happ/lib/plugins" \
          --set QML2_IMPORT_PATH "$out/opt/happ/lib/qml"

        makeWrapper $out/opt/happ/bin/happd $out/bin/happd \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}:$out/opt/happ/lib"
  '';

  dontStrip = true;

  meta = {
    description = "Happ proxy utility desktop client";
    homepage = "https://github.com/Happ-proxy/happ-desktop";
    license = lib.licenses.unfree; # no explicit license found
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
