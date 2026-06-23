{ inputs, pkgs, config, ... }: {
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = {
    enable = true;

    # Цветовая схема — Gruvbox Dark (Medium)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    polarity = "dark";

    # Шрифты
    fonts = {
      monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      sizes = {
        applications = 12;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };

    # Курсор
    cursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    # Обои — не заданы. Чтобы добавить: stylix.image = ./wallpaper.jpg;
    # image = null; (по умолчанию)

    # Какие приложения темизировать
    targets = {
      kde.enable = true;
      qt.enable = true;
      gtk.enable = true;
      fish.enable = true;
      neovim.enable = true;
      starship.enable = true;
      tmux.enable = true;
      fzf.enable = true;
      zed.enable = true;

      # Отключено — управляется через dotfiles.nix с кастомными конфигами
      ghostty.enable = false;
      yazi.enable = false;
      firefox.enable = false; # без profileNames темизация Firefox не работает
    };
  };
}
