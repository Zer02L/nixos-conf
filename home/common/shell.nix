{ config, pkgs, lib, ... }: {

  # ============================================================
  # 1. SHELLS
  # ============================================================

  # --- Zsh как login shell (системный, не трогаем) ---
  # Zsh нужен для POSIX-совместимости и работы Herdr/Workmux
  programs.zsh = {
    enable = true;
    # Настраиваем zsh так, чтобы при интерактивном запуске автоматически
    # переключался на fish (если fish доступен)
    initContent = lib.mkBefore ''
      # Запускаем fish только в интерактивных сессиях, не в скриптах
      if [[ -o interactive ]] && [[ -x ${pkgs.fish}/bin/fish ]]; then
        # Не запускаем fish, если мы уже в fish (защита от рекурсии)
        if [[ "$(${pkgs.procps}/bin/ps -p $PPID -o comm=)" != "fish" ]]; then
          exec ${pkgs.fish}/bin/fish
        fi
      fi
    '';
  };

  # --- Fish как интерактивный shell ---
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Отключаем приветствие
      set fish_greeting
      source $HOME/nixos-conf/dotfiles/fish/config.fish
    '';
    # Плагины (пример: grc для цветного вывода)
    plugins = [
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ];

  };

  # home.packages = with pkgs; [
  #   fishPlugins.bass
  #   fishPlugins.fzf-fish
  #   fishPlugins.autopair
  #   fishPlugins.sponge
  #   fishPlugins.done
  #   fishPlugins.forgit
  # ];

  # ============================================================
  # 2. ТЕРМИНАЛЫ
  # ============================================================

  # --- Kitty ---
  programs.kitty = {
    enable = true;
    # Интеграция с fish для корректной работы shell integration
    shellIntegration.enableFishIntegration = true;
    settings = {
      # Указываем fish как оболочку по умолчанию для Kitty
      shell = "${pkgs.fish}/bin/fish";
    };
  };

  # --- Ghostty ---
  programs.ghostty = {
    enable = true;
    # Включаем интеграции со всеми тремя shell
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    # settings = {

    #   # Ghostty сам определит fish, если он есть в PATH
    #   # или можно указать явно:
    #   # command = "${pkgs.fish}/bin/fish --login --interactive";
    # };
  };
}
