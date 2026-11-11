{ pkgs, ... }:
{
  programs.noctalia = {
    enable = true;
  };

  xdg.configFile."umbriel/config.toml".text = ''
    [general]
    autostart = ["noctalia"]

    [workspaces]
    back_and_forth = true

    [animation.scratchpad]
    dim = 0.0

    [input.keyboard]
    layout = "us,ru"
    options = "grp:alt_shift_toggle"

    [[scratchpad]]
    name = "terminal"
    spawn_when_empty = "ghostty --title=scratchpad-term --shell-integration-features=no-title"

    [keybinds]
    # --- Основные приложения и панели ---
    "Mod+Return" = "spawn ghostty"
    "Mod+Space" = "spawn noctalia msg panel-toggle launcher"
    "Mod+D" = "spawn noctalia msg panel-toggle launcher"
    "Mod+C" = "spawn noctalia msg panel-toggle control-center"
    "Mod+E" = "spawn ghostty -e yazi"
    "Mod+B" = "spawn firefox"

    # --- Управление окнами ---
    "Mod+Q" = "window-close"
    "Mod+F" = "window-toggle-fullscreen"
    "Mod+M" = "window-toggle-maximize"
    "Mod+V" = "window-toggle-floating"
    "Mod+W" = "column-toggle-tabbed"
    "Mod+P" = "window-toggle-pinned"

    # --- Навигация и фокус (Стрелки и HJKL) ---
    "Mod+Left" = "window-focus-left"
    "Mod+Right" = "window-focus-right"
    "Mod+Up" = "window-focus-up"
    "Mod+Down" = "window-focus-down"
    "Mod+H" = "window-focus-left"
    "Mod+L" = "window-focus-right"
    "Mod+K" = "window-focus-up"
    "Mod+J" = "window-focus-down"

    # --- Перемещение и обмен окон ---
    "Mod+Shift+Left" = "window-swap-left"
    "Mod+Shift+Right" = "window-swap-right"
    "Mod+Shift+Up" = "window-swap-up"
    "Mod+Shift+Down" = "window-swap-down"
    "Mod+Shift+H" = "window-swap-left"
    "Mod+Shift+L" = "window-swap-right"
    "Mod+Shift+K" = "window-swap-up"
    "Mod+Shift+J" = "window-swap-down"

    # --- Изменение размера (Resize) ---
    "Mod+Ctrl+Left" = "window-modify-width-right -0.05"
    "Mod+Ctrl+Right" = "window-modify-width-right 0.05"
    "Mod+Ctrl+Up" = "window-modify-height-down 0.05"
    "Mod+Ctrl+Down" = "window-modify-height-down -0.05"
    "Mod+Equal" = "window-cycle-primary-extent"

    # --- Раскладки (Layouts: Scrolling / Dwindle / Master) ---
    "Mod+R" = "workspace-set-layout toggle scrolling dwindle master"

    # --- Обзор и интерактивная шпаргалка хоткеев ---
    "Mod+Tab" = "overview-toggle"
    "Mod+Slash" = "cheatsheet-toggle"

    # --- Scratchpad (Выпадающий терминал и карман для окон) ---
    "Mod+grave" = "scratchpad-toggle terminal"
    "Mod+Cyrillic_io" = "scratchpad-toggle terminal"
    "Mod+Minus" = "scratchpad-toggle terminal"
    "Mod+Shift+Minus" = "window-toggle-scratchpad terminal"

    # --- Рабочие столы 1-9 ---
    "Mod+1" = "workspace-switch 1"
    "Mod+2" = "workspace-switch 2"
    "Mod+3" = "workspace-switch 3"
    "Mod+4" = "workspace-switch 4"
    "Mod+5" = "workspace-switch 5"
    "Mod+6" = "workspace-switch 6"
    "Mod+7" = "workspace-switch 7"
    "Mod+8" = "workspace-switch 8"
    "Mod+9" = "workspace-switch 9"

    "Mod+Shift+1" = "window-move-to-workspace 1"
    "Mod+Shift+2" = "window-move-to-workspace 2"
    "Mod+Shift+3" = "window-move-to-workspace 3"
    "Mod+Shift+4" = "window-move-to-workspace 4"
    "Mod+Shift+5" = "window-move-to-workspace 5"
    "Mod+Shift+6" = "window-move-to-workspace 6"
    "Mod+Shift+7" = "window-move-to-workspace 7"
    "Mod+Shift+8" = "window-move-to-workspace 8"
    "Mod+Shift+9" = "window-move-to-workspace 9"

    # --- Скриншоты через Noctalia ---
    "Print" = "spawn noctalia msg screenshot-annotate"
    "Shift+Print" = "spawn noctalia msg screenshot-fullscreen"
    "Mod+Print" = "spawn noctalia msg screenshot-window"

    # --- Мультимедиа и громкость (Noctalia OSD) ---
    "XF86AudioRaiseVolume" = "spawn noctalia msg volume-up 5"
    "XF86AudioLowerVolume" = "spawn noctalia msg volume-down 5"
    "XF86AudioMute" = "spawn noctalia msg volume-mute"
    "XF86AudioMicMute" = "spawn noctalia msg mic-mute"
    "XF86AudioPlay" = "spawn noctalia msg media play-pause"
    "XF86AudioNext" = "spawn noctalia msg media next"
    "XF86AudioPrev" = "spawn noctalia msg media previous"

    # --- Сессия и экран блокировки ---
    "Mod+Escape" = "spawn noctalia msg session lock"
    "Mod+Shift+E" = "session-quit"

    # === ПРАВИЛА ОКОН (Автоматическое распределение по столам) ===
    # Выпадающий scratchpad терминал сверху экрана (затемнение фона управляется через [animation.scratchpad])
    [[window_rule]]
    match = { title = "^scratchpad-term$" }
    default_floating = true
    default_floating_size = { width = 0.8, height = 0.55 }
    default_position = { anchor = "top", x = 0, y = 40 }

    # Диалоговые окна по умолчанию плавающие с легким затемнением
    [[window_rule]]
    match = { is_dialog = true }
    default_floating = true
    dim_behind = 0.35

    # Плавающее окно для Yazi (файловый менеджер открывается небольшим окном по центру с затемнением)
    [[window_rule]]
    match = { title = ".*[Yy]azi.*" }
    default_floating = true
    default_floating_size = { width = 0.6, height = 0.65 }
    default_position = { anchor = "center", x = 0, y = 0 }
    dim_behind = 0.35

    # Стол 1: Терминал и консольные утилиты
    [[window_rule]]
    match = { app_id = "^(ghostty|com\\.mitchellh\\.ghostty|kitty|Alacritty|foot)$" }
    default_workspace = 1

    # Стол 2: Браузеры
    [[window_rule]]
    match = { app_id = "^(firefox|librewolf|mullvad-browser|chromium|google-chrome)$" }
    default_workspace = 2

    # Стол 3: Разработка и IDE
    [[window_rule]]
    match = { app_id = "^(zed|dev\\.zed\\.Zed|Code|code|vscodium|com\\.t3tools\\.T3Code|jetbrains-.*)$" }
    default_workspace = 3

    # Стол 4: Коммуникация и мессенджеры
    [[window_rule]]
    match = { app_id = "^(vesktop|discord|org\\.telegram\\.desktop|telegramdesktop|bitwarden)$" }
    default_workspace = 4

    # Стол 5: Заметки, медиа и продуктивность
    [[window_rule]]
    match = { app_id = "^(obsidian|super-productivity|blender|com\\.obsproject\\.Studio|mpv|gimp.*)$" }
    default_workspace = 5

    # Стол 6: Игры и лаунчеры (Окна Steam объединяются в единую колонку с вкладками)
    [[window_rule]]
    match = { app_id = "^(lutris|heroic)$" }
    default_workspace = 6

    # Главное окно Steam при первом запуске открывается на 6 столе
    [[window_rule]]
    match = { app_id = "^(steam|Steam)$", title = "^Steam$" }
    default_workspace = 6
    default_scrolling_column = "steam"
    default_column_display = "tabbed"

    # Все остальные окна Steam (Friends List, чаты) прикрепляются к колонке Steam, где бы она ни находилась
    [[window_rule]]
    match = { app_id = "^(steam|Steam)$" }
    default_scrolling_column = "steam"
    default_column_display = "tabbed"

    # Стол 7: Утилиты и сеть (плавающие)
    [[window_rule]]
    match = { app_id = "^(Happ|pavucontrol|org\\.pulseaudio\\.pavucontrol)$" }
    default_workspace = 7
    default_floating = true
  '';
}
