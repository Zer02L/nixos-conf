{ ... }: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        nil         # Nix language server
        nixpkgs-fmt # Nix formatter
        statix      # Nix linter
      ];
    };
  };
}
