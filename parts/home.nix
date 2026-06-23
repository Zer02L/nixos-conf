{ inputs, ... }: let
  inherit (inputs) nixpkgs home-manager;

  system = "x86_64-linux";

  mkHome = username: home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.${system};
    modules = [ ../home/${username} ];
    extraSpecialArgs = { inherit inputs; };
  };
in {
  flake.homeConfigurations = {
    "zerg@zerg" = mkHome "zerg";
    "zerg@nixos" = mkHome "zerg";
  };
}
