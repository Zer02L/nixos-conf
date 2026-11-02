# Overlay and centralized package registry for nixos-conf
final: prev:
let
  sources = final.callPackage ../_sources/generated.nix { };
in
{
  t3code = final.callPackage ./t3code.nix { inherit sources; };
  t3-cli = final.callPackage ./t3-cli.nix { inherit sources; };
  omp = final.callPackage ./omp.nix { inherit sources; };
  amethyst-mod-manager = final.callPackage ./amethyst-mod-manager.nix { inherit sources; };
}
