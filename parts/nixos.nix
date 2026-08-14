{ inputs, ... }:
let
  inherit (inputs) nixpkgs disko;
  inherit (inputs) nixpkgs-stable;

  system = "x86_64-linux";

  pkgs-stable = import nixpkgs-stable {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };

  mkNixos =
    host:
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs pkgs-stable; };
      modules = [
        disko.nixosModules.disko
        ../hosts/${host}
      ];
    };

  # Individual NixOS modules — один источник истины
  modules = {
    system = import ../modules/system.nix;
    nix = import ../modules/nix.nix;
    fonts = import ../modules/fonts.nix;
    chromium = import ../modules/programs/chromium.nix;
    steam = import ../modules/programs/steam.nix;
    admin-tools = import ../modules/programs/admin-tools.nix;
    nsjail = import ../modules/programs/nsjail.nix;
    nvidia = import ../modules/hardware/nvidia.nix;
    pipewire = import ../modules/services/pipewire.nix;
    zram = import ../modules/services/zram.nix;
    zapret = import ../modules/services/zapret.nix;
    # zapret2 = import ../modules/services/zapret2.nix;
    # cloudflare-warp = import ../modules/services/cloudflare-warp.nix;
    power = import ../modules/services/power.nix;
    postgresql = import ../modules/services/postgresql.nix;
    comfyui = import ../modules/services/comfyui.nix;
    omniroute = import ../modules/services/omniroute.nix;
    secrets = import ../modules/services/secrets.nix;
    networking = import ../modules/networking/base.nix;
    desktop = import ../modules/desktop/foundation.nix;
    plasma = import ../modules/desktop/plasma.nix;
    users-zerg = import ../modules/users/zerg.nix;
    #     firefox-librewolf-like = import ../home/common/firefox-librewolf-like.nix;
  };
in
{
  flake = {
    nixosConfigurations = {
      zerg = mkNixos "zerg";
    };
    # Individual + автогенерированный .default (импортирует всё)
    nixosModules = modules // {
      default = { ... }: {
        imports = builtins.attrValues modules;
      };
    };
  };
}
