{ lib
, appimageTools
, fetchurl
, fetchgit
, fetchFromGitHub
, dockerTools
, sources ? import ../_sources/generated.nix { inherit fetchgit fetchurl fetchFromGitHub dockerTools; }
}:

let
  inherit (sources.antigravity-manager) pname version src;

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Только то, чего нет в самом AppImage. gtk3, webkitgtk-4.1 (вместе с
  # WebKitWebProcess) и libayatana-appindicator там запакованы, а идут через
  # LD_LIBRARY_PATH, то есть приоритетнее FHS /usr/lib — держать их здесь
  # бессмысленно, это был мёртвый вес в замыкании.
  extraPkgs = pkgs: with pkgs; [
    # AppDir собирается сломанно: в него положен libgcrypt.so.20, но его
    # зависимость libgpg-error.so.0 — нет. Без неё бинарник падает ещё на
    # стадии загрузчика: "error while loading shared libraries:
    # libgpg-error.so.0". ldd по всем ELF внутри AppImage показывает, что
    # это единственная недостающая библиотека.
    libgpg-error

    # Тут нужен именно он, хотя libayatana-appindicator3.so.1 запакован в
    # AppImage: приложение ищет AppIndicator по FHS-окружению, а не по
    # LD_LIBRARY_PATH AppImage. Без этого пункта в лог падает
    # "detected without AppIndicator libraries; disabling tray by default"
    # и трей отключается. Проверено запуском.
    libayatana-appindicator
  ];

  # GIO_EXTRA_MODULES задаёт хостовая сессия NixOS под системный glib 2.88,
  # а внутри AppImage грузится собственный glib 2.72 — хостовый модуль dconf
  # падает с "undefined symbol: g_assertion_message_cmpint". Совместимый
  # libdconfsettings.so у AppImage есть (его поднимает GIO_MODULE_DIR из
  # apprun-hooks), так что хостовый модуль тут только шумит.
  extraBwrapArgs = [ "--unsetenv" "GIO_EXTRA_MODULES" ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps

    # Имя desktop-файла внутри AppImage не зафиксировано (productName содержит пробел) — ищем его
    desktopSrc=$(find ${appimageContents} -maxdepth 4 -name '*.desktop' -print -quit || true)
    if [ -n "$desktopSrc" ]; then
      install -m 444 -D "$desktopSrc" $out/share/applications/antigravity-manager.desktop
      sed -i \
        -e 's|^Exec=.*|Exec=antigravity-manager %U|' \
        -e 's|^Icon=.*|Icon=antigravity-manager|' \
        -e 's|^Categories=.*|Categories=Development;Utility;|' \
        $out/share/applications/antigravity-manager.desktop
    fi

    # Иконка: первый попавшийся png из стандартных каталогов AppImage
    iconSrc=""
    for c in \
      "${appimageContents}"/usr/share/icons/hicolor/512x512/apps/*.png \
      "${appimageContents}"/usr/share/icons/hicolor/256x256/apps/*.png \
      "${appimageContents}"/usr/share/icons/hicolor/128x128/apps/*.png \
      "${appimageContents}"/*.png; do
      if [ -f "$c" ]; then
        iconSrc="$c"
        break
      fi
    done
    if [ -n "$iconSrc" ]; then
      install -m 444 -D "$iconSrc" $out/share/icons/hicolor/512x512/apps/antigravity-manager.png
      install -m 444 -D "$iconSrc" $out/share/pixmaps/antigravity-manager.png
    fi
  '';

  meta = with lib; {
    description = "Antigravity account manager and local API relay: multi-account switching, protocol conversion, model routing";
    homepage = "https://github.com/lbjlaq/Antigravity-Manager";
    license = licenses.cc-by-nc-sa-40;
    platforms = [ "x86_64-linux" ];
    mainProgram = "antigravity-manager";
  };
}
