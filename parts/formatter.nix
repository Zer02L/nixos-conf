{ ... }: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.writeShellScriptBin "nixfmt-wrapper" ''
      if [ $# -eq 0 ]; then
        exec ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt .
      else
        exec ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt "$@"
      fi
    '';
  };
}
