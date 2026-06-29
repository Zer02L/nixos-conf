{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    fishPlugins.bass
    fishPlugins.fzf-fish
    fishPlugins.autopair
    fishPlugins.sponge
    fishPlugins.done
    fishPlugins.forgit
  ];
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      source $HOME/nixos-conf/dotfiles/fish/config.fish
    '';
  };
}
