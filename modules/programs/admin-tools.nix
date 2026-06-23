{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    lazygit
    neovim
    wget
    curl
    cryptsetup
    btrfs-progs
    smartmontools
    nix-output-monitor

  ];

  programs.appimage.enable = true;
  programs.fish.enable = true;
}
