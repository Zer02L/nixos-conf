{ inputs, ... }: let
  inherit (inputs) nixpkgs home-manager;

  system = "x86_64-linux";

  mkHome = username: home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.${system};
    modules = [ ../home/${username} ];
    extraSpecialArgs = { inherit inputs; };
  };

  # Individual home-manager modules — один источник истины
  modules = {
    settings_hm           = import ../home/common/settings_hm.nix;
    cli-tools             = import ../home/common/cli-tools.nix;
    gui                   = import ../home/common/gui.nix;
    dev-tools             = import ../home/common/dev-tools.nix;
    dotfiles              = import ../home/common/dotfiles.nix;
    fish                  = import ../home/common/fish.nix;
    ghostty               = import ../home/common/ghostty.nix;
    git                   = import ../home/common/git.nix;
    firefox-librewolf-like = import ../home/common/firefox-librewolf-like.nix;
    git-hooks             = import ../home/common/git-hooks.nix;
    links                 = import ../home/common/links.nix;
    tmux                  = import ../home/common/tmux.nix;
    yazi                  = import ../home/common/yazi.nix;
    zapret-custom         = import ../home/common/zapret-custom.nix;
    stylix                = import ../home/common/stylix.nix;
  };
in {
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
