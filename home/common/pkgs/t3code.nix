{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../../../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.t3code) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps

    # Установка desktop-файла
    for f in ${appimageContents}/*.desktop; do
      if [ -f "$f" ]; then
        install -m 444 -D "$f" $out/share/applications/t3code.desktop
        substituteInPlace $out/share/applications/t3code.desktop \
          --replace-quiet 'Exec=AppRun' 'Exec=t3code' || true
      fi
    done

    # Установка иконок
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true
    fi
    for icon in ${appimageContents}/*.png; do
      if [ -f "$icon" ]; then
        install -m 444 -D "$icon" $out/share/pixmaps/t3code.png
        install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/t3code.png
      fi
    done
  '';

  meta = with lib; {
    description = "Agent harness control surface by Ping.gg";
    homepage = "https://github.com/pingdotgg/t3code";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
}
