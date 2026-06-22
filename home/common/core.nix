{
  config,
  lib,
  pkgs,
  ...
}:
{
  # KDE/Plasma устанавливает GIT_ASKPASS=ksshaskpass, который не работает
  # внутри neovim/lazy.nvim. Переопределяем на /usr/bin/false.
  home.sessionVariables.GIT_ASKPASS = "/usr/bin/false";
  home.stateVersion = "26.05";

  home.packages =
    (with pkgs; [
      # terminal
      neovim
      bat
      eza
      lazygit
      fzf
      ripgrep-all
      btop
      fastfetch
      starship
      zoxide
      nix-output-monitor
      devenv
      nodejs_24

      # media
      mpv
      obs-studio
      obs-studio-plugins.obs-vkcapture # захват игр (Vulkan/OpenGL) на Wayland

      # network
      bitwarden-cli
      zapret2
      v2rayn
      vesktop
      mullvad-browser
      telegram-desktop

      # productivity
      handy
      super-productivity
      activitywatch
      obsidian

      zed-editor-fhs
      vscode-fhs

      zrok

      blender
      onlyoffice-desktopeditors
    ]);

  nixpkgs.config = {
    allowUnfree = true;
  };
  programs.home-manager.enable = true;
}
