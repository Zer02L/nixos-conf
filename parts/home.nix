{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager nixpkgs-stable;

  system = "x86_64-linux";

  pkgs-stable = import nixpkgs-stable {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };

  mkHome =
    username:
    let
      pkgsCustom = nixpkgs.legacyPackages.${system}.extend (import ../pkgs/default.nix);
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsCustom;
      modules = [ ../home/${username} ];
      extraSpecialArgs = { inherit inputs pkgs-stable; };
    };

  # Individual home-manager modules — один источник истины
  modules = {
    shell = import ../home/common/shell.nix;
    settings_hm = import ../home/common/settings_hm.nix;
    cli-tools = import ../home/common/cli-tools.nix;
    gui-programs = import ../home/common/gui-programs.nix;
    dev-tools = import ../home/common/dev-tools.nix;
    dotfiles = import ../home/common/dotfiles.nix;
    git = import ../home/common/git.nix;
    firefox-librewolf-like = import ../home/common/firefox-librewolf-like.nix;
    git-hooks = import ../home/common/git-hooks.nix;
    links = import ../home/common/links.nix;
    tmux = import ../home/common/tmux.nix;
    # secrets = import ../home/common/secrets.nix;
    yazi = import ../home/common/yazi.nix;
    zapret-custom = import ../home/common/zapret-custom.nix;
    # karousel = import ../home/common/karousel.nix;
    mangohud = import ../home/common/mangohud.nix;
    plasma = import ../home/common/plasma.nix;
    noctalia = import ../home/common/noctalia.nix;
    stylix = import ../home/common/stylix.nix;
    # karing = import ../home/common/karing.nix;
    # pi-coding-agent = import ../home/common/pi-coding-agent.nix;
    distrobox = import ../home/common/distrobox.nix;
  };
in
{
  flake = {
    homeConfigurations = {
      "zerg@zerg" = mkHome "zerg";
      "zerg@nixos" = mkHome "zerg";
    };

    # Individual + автогенерированный .default (импортирует всё)
    homeManagerModules = modules // {
      default = { ... }: {
        imports = builtins.attrValues modules;
      };
    };
  };
}
