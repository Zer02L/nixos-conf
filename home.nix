{ config, pkgs, inputs, ... }: {
  home.username = "zerg";
  home.homeDirectory = "/home/zerg";
  
  # Версия состояния (оставьте ту, которая была при создании системы)
  home.stateVersion = "25.05"; 

  # Ваши пользовательские пакеты (например, LibreWolf и CLI-утилиты)
  home.packages = with pkgs; [

  ghostty
  
  neovim

  handy

  mpv

  zed-editor-fhs
  bat
  eza
  fzf
  ripgrep
  btop
  fastfetch
  nix-output-monitor 
   
  devenv

 # inputs.zed-flake.packages.${pkgs.system}.default

 # inputs.llm-agents.packages.${pkgs.system}.omp
 ];

  programs.librewolf = {
    enable = true;
    # ваши настройки settings = { ... };
  };

programs.fish.enable = true;

  # ЭТОТ ФЛАГ ОБЯЗАТЕЛЕН ДЛЯ СТАНДАЛОН-РЕЖИМА
  # Он автоматически устанавливает и обновляет саму утилиту `home-manager` в ваш профиль
  programs.home-manager.enable = true;
	home.file."Downloads".source = config.lib.file.mkOutOfStoreSymlink "/mnt/downloads";
	home.file.".local/share/Steam".source = config.lib.file.mkOutOfStoreSymlink "/mnt/steam";
}

