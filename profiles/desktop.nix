# Desktop profile — graphical environment, audio, fonts, display manager
{ config, lib, pkgs, ... }:
{
  imports = [
    ./core.nix
    ../modules/fonts.nix
    ../modules/desktop/foundation.nix
    ../modules/desktop/plasma.nix
    ../modules/services/pipewire.nix
    ../modules/programs/common.nix
    ../modules/services/flatpak.nix
  ];
}
