# Plasma configuration via plasma-manager
#
# Window rules migrated from kwin-rules.nix:
# Desktop layout:
#   1 — Терминал (ghostty + neovim)
#   2 — Браузер (librewolf, mullvad-browser)
#   3 — IDE (zed, vscode)
#   4 — Коммуникация (vesktop, telegram-desktop)
#   5 — Прочее (obsidian, super-productivity, blender, onlyoffice)
#
# WMClass определяется через: xprop | grep WM_CLASS
# Режим: Apply Initially — можно перетащить вручную.
#         Force — жёсткая привязка.
#
# Karousel (karousel.nix) тайлингует окна внутри рабочего стола;
# эти правила управляют ТОЛЬКО тем, какой стол получает окно при запуске.
{ inputs, config, pkgs, lib, ... }:

let
  # Helper: создаёт правило для назначения окна на виртуальный стол
  mkDesktopRule = {
    name,           # описание правила
    wmclass,        # WM_CLASS (exact match)
    desktop,        # номер виртуального стола
    force ? false,  # Force или Apply Initially
  }: {
    description = name;
    match = {
      window-class = {
        value = wmclass;
        type = "exact";
        match-whole = true;
      };
    };
    apply.desktop = {
      value = desktop;
      apply = if force then "force" else "initially";
    };
  };
in
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  programs.plasma = {
    enable = true;

    # === Window Rules ===
    window-rules = [
      (mkDesktopRule { name = "Ghostty";          wmclass = "ghostty";               desktop = 1; })
      (mkDesktopRule { name = "Kitty";            wmclass = "kitty";                 desktop = 1; })

      (mkDesktopRule { name = "Librewolf";        wmclass = "librewolf";             desktop = 2; })
      (mkDesktopRule { name = "Firefox";          wmclass = "firefox";               desktop = 2; })
      (mkDesktopRule { name = "Mullvad Browser";  wmclass = "mullvad-browser";       desktop = 2; })

      (mkDesktopRule { name = "Zed";              wmclass = "zed";                   desktop = 3; })
      (mkDesktopRule { name = "VS Code";          wmclass = "Code";                  desktop = 3; })
      (mkDesktopRule { name = "JetBrains";        wmclass = "jetbrains-*";           desktop = 3; })

      (mkDesktopRule { name = "Vesktop";          wmclass = "vesktop";               desktop = 4; })
      (mkDesktopRule { name = "Telegram Desktop"; wmclass = "org.telegram.desktop";  desktop = 4; })
      (mkDesktopRule { name = "Bitwarden";        wmclass = "bitwarden";             desktop = 4; })

      (mkDesktopRule { name = "Obsidian";         wmclass = "obsidian";              desktop = 5; })
      (mkDesktopRule { name = "Super Productivity"; wmclass = "super-productivity";  desktop = 5; })
      (mkDesktopRule { name = "Blender";          wmclass = "blender";               desktop = 5; })
      (mkDesktopRule { name = "OnlyOffice";       wmclass = "onlyoffice-desktopeditors"; desktop = 5; })
      (mkDesktopRule { name = "OBS Studio";       wmclass = "com.obsproject.Studio"; desktop = 5; })
      (mkDesktopRule { name = "mpv";              wmclass = "mpv";                   desktop = 5; })
    ];

    # === KWin ===
    kwin = {
      # Отключаем edge barrier, появившийся в Plasma 6.1
      edgeBarrier = 0;
      cornerBarrier = false;
    };

    # === Screen Locker ===
    kscreenlocker = {
      timeout = 10;
      lockOnResume = true;
    };

    # === Workspace ===
    workspace = {
      clickItemTo = "open";
      # Cursor и шрифты управляются через Stylix
    };
  };
}
