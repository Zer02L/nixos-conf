{
  description = "Моя конфигурация NixOS с Flake и Disko";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapret-discord-youtube.url = "github:kartavkun/zapret-discord-youtube";

  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        zerg = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./hosts/zerg
          ];
        };
      };

      homeConfigurations =
        let
          mkHome =
            username:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ ./home/${username} ];
              extraSpecialArgs = { inherit inputs; };
            };
          zergHome = mkHome "zerg";
        in
        {
          "zerg@zerg" = zergHome;
          "zerg@nixos" = mkHome "zerg";
        };
    };
}
