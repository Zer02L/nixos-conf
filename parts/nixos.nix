{ inputs, ... }: let
  inherit (inputs) nixpkgs disko;

  system = "x86_64-linux";

  mkNixos = host: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      disko.nixosModules.disko
      ../hosts/${host}
    ];
  };
in {
  flake = {
    nixosConfigurations = {
      zerg = mkNixos "zerg";
    };
    nixosModules = {
      system          = import ../modules/system.nix;
      nix             = import ../modules/nix.nix;
      fonts           = import ../modules/fonts.nix;
      brave           = import ../modules/programs/brave.nix;
      steam           = import ../modules/programs/steam.nix;
      admin-tools     = import ../modules/programs/admin-tools.nix;
      nvidia          = import ../modules/hardware/nvidia.nix;
      display-manager = import ../modules/services/display-manager.nix;
      pipewire        = import ../modules/services/pipewire.nix;
      zram            = import ../modules/services/zram.nix;
      zapret          = import ../modules/services/zapret.nix;
      power           = import ../modules/services/power.nix;
      postgresql      = import ../modules/services/postgresql.nix;
      omniroute       = import ../modules/services/omniroute.nix;
      networking      = import ../modules/networking/default.nix;
      users-zerg      = import ../modules/users/zerg.nix;

      # Aggregator — импортирует все модули разом
      default         = import ../modules/default.nix;
    };
  };
}
