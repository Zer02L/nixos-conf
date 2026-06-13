{ config, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    sensibleOnTop = true;
    escapeTime = 10;
    historyLimit = 5000;
    baseIndex = 1;
    clock24 = true;
    extraConfig = ''
      source-file ~/nixos-conf/dotfiles/tmux/tmux.conf
    '';
    plugins = with pkgs.tmuxPlugins; [
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_flavor "mocha"
        '';
      }
    ];
  };
}
