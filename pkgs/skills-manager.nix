{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.skills-manager) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libgpg-error
    libayatana-appindicator
  ];

  extraBwrapArgs = [ "--unsetenv" "GIO_EXTRA_MODULES" ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps

    # Desktop file installation
    desktopSrc=$(find ${appimageContents} -maxdepth 4 -name '*.desktop' -print -quit || true)
    if [ -n "$desktopSrc" ]; then
      install -m 444 -D "$desktopSrc" $out/share/applications/skills-manager.desktop
      substituteInPlace $out/share/applications/skills-manager.desktop \
        --replace-quiet 'Exec=AppRun' 'Exec=skills-manager' || true
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
        install -m 444 -D "$icon" $out/share/pixmaps/skills-manager.png
        install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/skills-manager.png
        break
      fi
    done
  '';

  meta = with lib; {
    description = "One app to manage AI agent skills across all your coding tools";
    homepage = "https://skillsmanager.dev";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "skills-manager";
  };
}
