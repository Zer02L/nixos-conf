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
  antigravity-manager = final.callPackage ./antigravity-manager.nix { inherit sources; };
  # Prebuilt binaries — nixpkgs versions fail to build in this rev (zstd-sys / aws-lc-sys)
  protonup-rs = final.callPackage ./protonup-rs.nix { inherit sources; };
  obscura = final.callPackage ./obscura.nix { inherit sources; };
  artcraft-launcher = final.callPackage ./artcraft-launcher.nix { inherit sources; };
  brave = final.callPackage ./brave.nix {
    inherit sources;
    brave = prev.brave;
  };
  brave-origin = final.callPackage ./brave-origin.nix {
    inherit sources;
    brave-origin = prev.brave-origin;
  };
  brave-browser = final.brave;
  pi-coding-agent = final.callPackage ./pi-coding-agent.nix { inherit sources; };
  pi = final.pi-coding-agent;
  creabim = final.callPackage ./creabim.nix { inherit sources; };
}
