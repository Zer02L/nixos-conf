{ lib
, fetchurl
, appimageTools
, libsecret
, libnotify
, pipewire
}:

let
  pname = "wfhelper";
  version = "2.1.1";

  src = fetchurl {
    url = "https://github.com/WFHelper/WFHelper/releases/download/v${version}/WFHelper-${version}.AppImage";
    hash = "sha256-04lf525fLcWC9yI6Bw4PZn0MUZNUfKrypvVqfoCvRdM=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libsecret
    libnotify
    pipewire
  ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/wfhelper.desktop $out/share/applications/wfhelper.desktop
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/974x974/apps/wfhelper.png $out/share/icons/hicolor/512x512/apps/wfhelper.png
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/974x974/apps/wfhelper.png $out/share/pixmaps/wfhelper.png

    substituteInPlace $out/share/applications/wfhelper.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=wfhelper %U'
  '';

  meta = with lib; {
    description = "Desktop Warframe companion: inventory, relic reward scanner, market prices and analytics";
    homepage = "https://github.com/WFHelper/WFHelper";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "wfhelper";
  };
}
