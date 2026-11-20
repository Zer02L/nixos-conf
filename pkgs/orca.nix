{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.orca) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps

    # Desktop file installation
    desktopSrc=$(find ${appimageContents} -maxdepth 4 -name '*.desktop' -print -quit || true)
    if [ -n "$desktopSrc" ]; then
      install -m 444 -D "$desktopSrc" $out/share/applications/orca-ide.desktop
      sed -i -e 's|^Exec=.*|Exec=orca-ide %U|' $out/share/applications/orca-ide.desktop
      ln -s $out/share/applications/orca-ide.desktop $out/share/applications/orca-ai.desktop
    fi

    # Icons installation
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true
    fi
    for icon in \
      "${appimageContents}"/usr/share/icons/hicolor/512x512/apps/*.png \
      "${appimageContents}"/usr/share/icons/hicolor/256x256/apps/*.png \
      "${appimageContents}"/*.png; do
      if [ -f "$icon" ]; then
        install -m 444 -D "$icon" $out/share/pixmaps/orca-ide.png
        install -m 444 -D "$icon" $out/share/pixmaps/orca-ai.png
        install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/orca-ide.png
        install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/orca-ai.png
        break
      fi
    done

    # Upstream on Linux installs as orca-ide to avoid shadowing the GNOME Orca screen reader.
    # Provide orca-ide and orca-ai, but remove/rename bin/orca.
    if [ -f "$out/bin/orca" ]; then
      mv $out/bin/orca $out/bin/orca-ide
    fi
    ln -s $out/bin/orca-ide $out/bin/orca-ai
  '';

  meta = with lib; {
    description = "Agentic development environment (ADE) for orchestrating AI coding agents";
    homepage = "https://github.com/stablyai/orca";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "orca-ide";
  };
}
