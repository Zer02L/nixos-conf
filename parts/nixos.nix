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
  flake.nixosConfigurations = {
    zerg = mkNixos "zerg";
    # Добавьте новый хост по образцу:
    # nixos = mkNixos "nixos";
  };
}
