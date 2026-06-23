# KWin Window Rules — автоматическое назначение приложений на виртуальные рабочие столы
#
# Раскладка:
#   1 — Терминал (ghostty + neovim)
#   2 — Браузер (librewolf, mullvad-browser)
#   3 — IDE (zed, vscode)
#   4 — Коммуникация (vesktop, telegram-desktop)
#   5 — Прочее (obsidian, super-productivity, blender, onlyoffice)
#
# WMClass определяется через: xprop | grep WM_CLASS
# Режим: Apply Initially (desktopsrule=0) — можно перетащить вручную.
#         Force (desktopsrule=2) — жёсткая привязка.
#
# Карусель (karousel.nix) тайлингует окна внутри рабочего стола;
# эти правила управляют ТОЛЬКО тем, какой стол получает окно при запуске.

{ config, pkgs, lib, ... }:

let
  # Сериализация значений для kwinrulesrc (без кавычек строк, без JSON-формата)
  serializeValue = v:
    if builtins.isBool v then (if v then "true" else "false")
    else if builtins.isInt v then builtins.toString v
    else if builtins.isString v then v
    else builtins.toJSON v;

  # Вспомогательная функция для создания правила
  mkRule = {
    name,
    wmclass ? null,
    title ? null,
    desktop,
    force ? false,
  }:
    {
      Description = name;
      desktops = builtins.toString desktop;
      desktopsrule = if force then 2 else 0; # 0 = Apply Initially, 2 = Force
    }
    // lib.optionalAttrs (wmclass != null) {
      wmclass = wmclass;
      wmclassmatch = 2; # exact match
      wmclasscomplete = true;
    }
    // lib.optionalAttrs (title != null) {
      title = title;
      titlematch = 2; # exact match
    };

  rules = [
    # === Desktop 1: Терминал ===
    (mkRule { name = "Ghostty"; wmclass = "ghostty"; desktop = 1; })
    (mkRule { name = "Kitty"; wmclass = "kitty"; desktop = 1; })

    # === Desktop 2: Браузер ===
    (mkRule { name = "Librewolf"; wmclass = "librewolf"; desktop = 2; })
    (mkRule { name = "Firefox"; wmclass = "firefox"; desktop = 2; })
    (mkRule { name = "Mullvad Browser"; wmclass = "mullvad-browser"; desktop = 2; })

    # === Desktop 3: IDE ===
    (mkRule { name = "Zed"; wmclass = "zed"; desktop = 3; })
    (mkRule { name = "VS Code"; wmclass = "Code"; desktop = 3; })
    (mkRule { name = "JetBrains (IntelliJ и др.)"; wmclass = "jetbrains-*"; desktop = 3; })

    # === Desktop 4: Коммуникация ===
    (mkRule { name = "Vesktop (Discord)"; wmclass = "vesktop"; desktop = 4; })
    (mkRule { name = "Telegram Desktop"; wmclass = "org.telegram.desktop"; desktop = 4; })
    (mkRule { name = "Bitwarden"; wmclass = "bitwarden"; desktop = 4; })

    # === Desktop 5: Прочее ===
    (mkRule { name = "Obsidian"; wmclass = "obsidian"; desktop = 5; })
    (mkRule { name = "Super Productivity"; wmclass = "super-productivity"; desktop = 5; })
    (mkRule { name = "Blender"; wmclass = "blender"; desktop = 5; })
    (mkRule { name = "OnlyOffice"; wmclass = "onlyoffice-desktopeditors"; desktop = 5; })
    (mkRule { name = "OBS Studio"; wmclass = "com.obsproject.Studio"; desktop = 5; })
    (mkRule { name = "mpv"; wmclass = "mpv"; desktop = 5; })
  ];

  ruleCount = builtins.length rules;
  ruleNames = builtins.genList (n: builtins.toString (n + 1)) ruleCount;

  # Собираем секции [1], [2], ... [N]
  ruleSections = lib.concatStringsSep "\n\n" (
    map (i:
      let
        rule = builtins.elemAt rules (builtins.fromJSON i - 1);
        pairs = lib.mapAttrsToList (n: v: "${n}=${serializeValue v}") rule;
      in
      "[${i}]\n${lib.concatStringsSep "\n" pairs}"
    ) ruleNames
  );

  kwinrulesrc = ''
    [General]
    count=${builtins.toString ruleCount}
    rules=${lib.concatStringsSep "," ruleNames}

    ${ruleSections}
  '';
in
{
  xdg.configFile."kwinrulesrc" = {
    text = kwinrulesrc;
    force = true;
  };
}
