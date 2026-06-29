{ inputs, ... }:
let
  inherit (inputs) nixpkgs disko;

  system = "x86_64-linux";

  mkNixos =
    host:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
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
    power = import ../modules/services/power.nix;
    postgresql = import ../modules/services/postgresql.nix;
    omniroute = import ../modules/services/omniroute.nix;
    networking = import ../modules/networking/base.nix;
    desktop = import ../modules/desktop/foundation.nix;
    plasma = import ../modules/desktop/plasma.nix;
    users-zerg = import ../modules/users/zerg.nix;
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
