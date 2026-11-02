# Home-Manager profile: Terminal/CLI environment (shared across desktop & server)
{ config, lib, pkgs, ... }:
{
  imports = [
    ../common/shell.nix
    ../common/settings_hm.nix
    ../common/cli-tools.nix
    ../common/dev-tools.nix
    ../common/dotfiles.nix
    ../common/git.nix
    ../common/git-hooks.nix
    ../common/tmux.nix
    ../common/yazi.nix
    ../common/pi-coding-agent.nix
    ../common/distrobox.nix
  ];
}
