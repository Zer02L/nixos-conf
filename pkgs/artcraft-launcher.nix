{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.artcraft-launcher) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps

    # Установка desktop-файла
    if [ -f "${appimageContents}/ai.storyteller.artcraft-launcher.desktop" ]; then
      install -m 444 -D "${appimageContents}/ai.storyteller.artcraft-launcher.desktop" \
        $out/share/applications/artcraft-launcher.desktop
      substituteInPlace $out/share/applications/artcraft-launcher.desktop \
        --replace-quiet 'Exec=artcraft-launcher' 'Exec=artcraft-launcher' || true
    fi

    # Установка иконок
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      mkdir -p $out/share
      cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true
    fi

    if [ -f "${appimageContents}/ai.storyteller.artcraft-launcher.png" ]; then
      install -m 444 -D "${appimageContents}/ai.storyteller.artcraft-launcher.png" \
        $out/share/pixmaps/artcraft-launcher.png
      install -m 444 -D "${appimageContents}/ai.storyteller.artcraft-launcher.png" \
        $out/share/pixmaps/ai.storyteller.artcraft-launcher.png
    fi
  '';

  meta = with lib; {
    description = "Launcher and update manager for the ArtCraft creative apps suite";
    homepage = "https://getartcraft.com/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "artcraft-launcher";
  };
}
