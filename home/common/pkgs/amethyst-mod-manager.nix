{ lib
, stdenv
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, dwarfs
, makeWrapper
, sources ? import ../../../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.amethyst-mod-manager) pname version src;
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    dwarfs
    makeWrapper
  ];

  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/amethyst-mod-manager
    dwarfsextract -i $src -o $out/opt/amethyst-mod-manager

    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps $out/share/pixmaps

    # Symlink / wrap executable
    makeWrapper $out/opt/amethyst-mod-manager/AppRun $out/bin/amethyst-mod-manager \
      --argv0 amethyst-mod-manager

    ln -s amethyst-mod-manager $out/bin/amethyst
    ln -s amethyst-mod-manager $out/bin/mod-manager

    # Install desktop entry
    if [ -f "$out/opt/amethyst-mod-manager/mod-manager.desktop" ]; then
      cp "$out/opt/amethyst-mod-manager/mod-manager.desktop" "$out/share/applications/amethyst-mod-manager.desktop"
    elif [ -f "$out/opt/amethyst-mod-manager/amethyst-mod-manager.desktop" ]; then
      cp "$out/opt/amethyst-mod-manager/amethyst-mod-manager.desktop" "$out/share/applications/amethyst-mod-manager.desktop"
    fi

    # Ensure Exec points to amethyst-mod-manager and add protocol handlers
    substituteInPlace $out/share/applications/amethyst-mod-manager.desktop \
      --replace-quiet 'Exec=mod-manager %u' 'Exec=amethyst-mod-manager %u' \
      --replace-quiet 'Icon=mod-manager' 'Icon=amethyst-mod-manager' || true

    # Add MimeType handlers for Nexus (nxm), Thunderstore (ror2mm), and generic (modl)
    if ! grep -q 'MimeType=' $out/share/applications/amethyst-mod-manager.desktop; then
      echo "MimeType=x-scheme-handler/nxm;x-scheme-handler/ror2mm;x-scheme-handler/modl;" >> $out/share/applications/amethyst-mod-manager.desktop
    fi

    # Install icons
    for icon in "$out/opt/amethyst-mod-manager"/mod-manager.png "$out/opt/amethyst-mod-manager"/.DirIcon; do
      if [ -f "$icon" ]; then
        cp "$icon" $out/share/pixmaps/amethyst-mod-manager.png
        cp "$icon" $out/share/icons/hicolor/256x256/apps/amethyst-mod-manager.png
        break
      fi
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Mod manager for Linux and Steam Deck";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "amethyst-mod-manager";
  };
}
