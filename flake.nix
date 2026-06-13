{
  description = "Моя конфигурация NixOS с Flake и Disko";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1k81BUZQj4So8dCTCBj8otjY1IMwRNQFjT2V8M0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    herdr.url = "github:ogulcancelik/herdr";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapret-discord-youtube.url = "github:kartavkun/zapret-discord-youtube";

    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      home-manager,
      herdr,
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
