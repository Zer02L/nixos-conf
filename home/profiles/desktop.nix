# Home-Manager profile: Full desktop environment (GUI, browsers, themes)
{ config, lib, pkgs, ... }:
{
  imports = [
    ./cli.nix
    ../common/gui-programs.nix
    ../common/firefox-librewolf-like.nix
    ../common/links.nix
    ../common/mangohud.nix
    ../common/plasma.nix
    ../common/stylix.nix
    ../common/zapret-custom.nix
  ];
}
