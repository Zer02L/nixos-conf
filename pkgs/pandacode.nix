{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.pandacode) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      # Заменяем устаревший bundled xdg-open, который ломается на KDE 6,
      # на вызов системного портала OpenURI (или хостового xdg-open).
      mkdir -p $out/usr/bin
      cat << 'EOF' > $out/usr/bin/xdg-open
      #!/bin/sh
      target="$1"
      case "$target" in
        http://*|https://*|file://*)
          if command -v gdbus >/dev/null 2>&1; then
            if gdbus call --session \
              --dest org.freedesktop.portal.Desktop \
              --object-path /org/freedesktop/portal/desktop \
              --method org.freedesktop.portal.OpenURI.OpenURI \
              "" "$target" "{}" >/dev/null 2>&1; then
              exit 0
            fi
          fi
          ;;
      esac

      if [ -x /run/current-system/sw/bin/xdg-open ]; then
        exec /run/current-system/sw/bin/xdg-open "$@"
      fi

      if command -v gio >/dev/null 2>&1; then
        exec gio open "$@"
      fi

      exit 1
      EOF
      chmod +x $out/usr/bin/xdg-open
    '';
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libgpg-error
    libayatana-appindicator
    glib
  ];

  extraBwrapArgs = [ "--unsetenv" "GIO_EXTRA_MODULES" ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps

    desktopSrc=$(find ${appimageContents} -maxdepth 4 -name '*.desktop' -print -quit || true)
    if [ -n "$desktopSrc" ]; then
      install -m 444 -D "$desktopSrc" $out/share/applications/pandacode.desktop
      sed -i \
        -e 's|^Exec=.*|Exec=pandacode %U|' \
        -e 's|^Icon=.*|Icon=pandacode|' \
        -e 's|^Categories=.*|Categories=Development;Utility;|' \
        $out/share/applications/pandacode.desktop
    fi

    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true
    fi
    for icon in \
      "${appimageContents}"/usr/share/icons/hicolor/512x512/apps/*.png \
      "${appimageContents}"/usr/share/icons/hicolor/256x256/apps/*.png \
      "${appimageContents}"/usr/share/icons/hicolor/128x128/apps/*.png \
      "${appimageContents}"/*.png; do
      if [ -f "$icon" ]; then
        install -m 444 -D "$icon" $out/share/pixmaps/pandacode.png
        install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/pandacode.png
        break
      fi
    done
  '';

  meta = with lib; {
    description = "PandaCode: a calm desktop workspace for coding agents";
    homepage = "https://github.com/aicodeking/pandacode";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pandacode";
  };
}
