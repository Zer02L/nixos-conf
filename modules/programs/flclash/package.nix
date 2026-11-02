{ lib
, stdenv
, dpkg
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
, gtk3
, glib
, cairo
, pango
, atk
, gdk-pixbuf
, libayatana-appindicator
, libepoxy
, libsecret
, sqlite
, libX11
, libxcomposite
, libxcursor
, libxdamage
, libxext
, libxfixes
, libxi
, libxrandr
, libxrender
, libxtst
, libGL
, udev
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../../../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.flclash) pname version src;
in
stdenv.mkDerivation rec {
  inherit pname version src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    gtk3
    glib
    cairo
    pango
    atk
    gdk-pixbuf
    libayatana-appindicator
    libepoxy
    libsecret
    sqlite
    udev
    libGL
    libX11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libjvm.so"
  ];

  dontUnpack = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/FlClash $out/bin $out/share

    dpkg -x $src .
    cp -r opt/FlClash/* $out/opt/FlClash/

    if [ -d "usr/share" ]; then
      cp -r usr/share/* $out/share/
    fi

    # Fix FlClash binary permissions
    chmod +x $out/opt/FlClash/FlClash
    chmod +x $out/opt/FlClash/FlClashCore
    chmod +x $out/opt/FlClash/FlClashHelperService

    # Wrap the GUI binary
    makeWrapper $out/opt/FlClash/FlClash $out/bin/flclash \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL udev libayatana-appindicator ]}:$out/opt/FlClash/lib"

    # Make uppercase symlink as well (since .desktop specifies Exec=FlClash %U)
    ln -s $out/bin/flclash $out/bin/FlClash

    runHook postInstall
  '';

  meta = with lib; {
    description = "A multi-platform proxy client based on ClashMeta, simple and easy to use";
    homepage = "https://github.com/chen08209/FlClash";
    platforms = [ "x86_64-linux" ];
    mainProgram = "flclash";
    license = licenses.gpl3Only;
  };
}
