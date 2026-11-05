{ inputs, ... }:
let
  overlay = import ../pkgs/default.nix;
in
{
  flake = {
    overlays.default = overlay;
  };

  perSystem = { pkgs, system, ... }:
    let
      pkgsWithCustom = pkgs.extend overlay;
    in
    {
      packages = {
        t3code = pkgsWithCustom.t3code;
        t3-cli = pkgsWithCustom.t3-cli;
        omp = pkgsWithCustom.omp;
        amethyst-mod-manager = pkgsWithCustom.amethyst-mod-manager;
        artcraft-launcher = pkgsWithCustom.artcraft-launcher;
      };
    };
}
