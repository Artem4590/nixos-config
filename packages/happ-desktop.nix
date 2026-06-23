{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  lib,
  libGL,
  libglvnd,
  e2fsprogs,
  zlib,
  fontconfig,
  freetype,
  libgpg-error,
  qt6,
  openssl,
  ...
}:

stdenv.mkDerivation rec {
  pname = "happ-desktop";
  version = "2.18.1";

  src = fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "12bzlyvbz4idz8na1a57diikriyf8hpkc5y9c8n8206kl4gfcw2i";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    libGL
    libglvnd
    stdenv.cc.cc.lib
    e2fsprogs
    zlib
    fontconfig
    freetype
    libgpg-error
    qt6.qtwayland
    openssl
  ];

  dontBuild = true;
  dontConfigure = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p deb-contents
    dpkg-deb -x $src deb-contents

    mkdir -p $out/opt
    cp -r deb-contents/opt/happ $out/opt/

    # Qt TLS plugin подгружает libssl/libcrypto через dlopen.
    # Добавляем symlinks в bundled libdir, чтобы плагин находил их по существующему RPATH.
    ln -s ${openssl.out}/lib/libssl.so.3 $out/opt/happ/lib/libssl.so.3
    ln -s ${openssl.out}/lib/libssl.so.3 $out/opt/happ/lib/libssl.so
    ln -s ${openssl.out}/lib/libcrypto.so.3 $out/opt/happ/lib/libcrypto.so.3
    ln -s ${openssl.out}/lib/libcrypto.so.3 $out/opt/happ/lib/libcrypto.so

    mkdir -p $out/bin
    ln -s $out/opt/happ/bin/Happ $out/bin/happ
    ln -s $out/opt/happ/bin/happd $out/bin/happd

    mkdir -p $out/share/applications
    substituteInPlace deb-contents/usr/share/applications/Happ.desktop \
      --replace-fail "/opt/happ/bin/Happ" "$out/bin/happ"
    cp deb-contents/usr/share/applications/Happ.desktop $out/share/applications/

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp deb-contents/usr/share/icons/hicolor/256x256/apps/happ.png $out/share/icons/hicolor/256x256/apps/

    mkdir -p $out/share/mime/packages
    cp deb-contents/usr/share/mime/packages/happ-mime.xml $out/share/mime/packages/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Happ Proxy Utility — cross-platform proxy/VPN client";
    homepage = "https://github.com/Happ-proxy/happ-desktop";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
