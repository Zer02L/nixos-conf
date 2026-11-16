{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, wrapGAppsHook3
, gtk3
, webkitgtk_4_1
, libsoup_3
, glib
, makeWrapper
, callPackage
, sources ? callPackage ../_sources/generated.nix { }
}:

let
  src-info = sources.kiri;
in
stdenv.mkDerivation rec {
  inherit (src-info) pname version src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/kiri $out/libexec/kiri $out/share

    # Install core daemon and cli
    install -Dm755 usr/bin/kiri-init $out/bin/kiri-init

    # Install GUI window into lib/kiri
    install -Dm755 usr/lib/kiri/kiri-window $out/lib/kiri/kiri-window
    ln -s $out/lib/kiri/kiri-window $out/bin/kiri-window

    # Install raw kiri cli into libexec and wrap it in bin/kiri
    install -Dm755 usr/bin/kiri $out/libexec/kiri/kiri-raw
    makeWrapper $out/libexec/kiri/kiri-raw $out/bin/kiri \
      --run 'if [ "$1" = "ui" ]; then shift; exec "'"$out/lib/kiri/kiri-window"'" ui "$@"; fi'

    # Copy bundled docker CLI tools and plugins
    cp -r usr/libexec/kiri/* $out/libexec/kiri/

    # Patch /usr/libexec/kiri/bin/docker in docker-wrapper script
    substituteInPlace $out/libexec/kiri/docker \
      --replace-fail "/usr/libexec/kiri/bin/docker" "$out/libexec/kiri/bin/docker"

    # Copy desktop file, icons and metadata
    cp -r usr/share/* $out/share/

    # Fix desktop file Exec path
    substituteInPlace $out/share/applications/kiri.desktop \
      --replace-fail "/usr/lib/kiri/kiri-window" "$out/lib/kiri/kiri-window"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A small, fast container runtime for macOS, Windows and Linux";
    homepage = "https://github.com/libracoder/kiri";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kiri";
  };
}
