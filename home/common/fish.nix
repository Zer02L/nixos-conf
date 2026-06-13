{ config, pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      source $HOME/nixos-conf/dotfiles/fish/config.fish
    '';
  };
}
