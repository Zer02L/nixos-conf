{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # KDE/Plasma устанавливает GIT_ASKPASS=ksshaskpass, который не работает
  # внутри neovim/lazy.nvim. Переопределяем на /usr/bin/false.
  home.sessionVariables.GIT_ASKPASS = "/usr/bin/false";
  home.stateVersion = "25.05";

  home.packages =
    (with pkgs; [
      # terminal
      neovim
      bat
      eza
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

      zrok

      antigravity-cli

    ])
    ++ [
      # flakes (requires pkgs. prefix due to hyphens in names)
      # inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp # better then pi agent
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default # better then cmux
    ];

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;
}
