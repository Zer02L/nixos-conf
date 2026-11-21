# Overlay and centralized package registry for nixos-conf
final: prev:
let
  sources = final.callPackage ../_sources/generated.nix { };
in
{
  t3code = final.callPackage ./t3code.nix { inherit sources; sourceKey = "t3code"; };
  t3code-nightly = final.callPackage ./t3code.nix { inherit sources; sourceKey = "t3code-nightly"; };
  t3-cli = final.callPackage ./t3-cli.nix { inherit sources; sourceKey = "t3-cli"; };
  t3-cli-nightly = final.callPackage ./t3-cli.nix { inherit sources; sourceKey = "t3-cli-nightly"; };
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
  kiri = final.callPackage ./kiri.nix { inherit sources; };
  opencode = final.callPackage ./opencode.nix { inherit sources; };
  orca = final.callPackage ./orca.nix { inherit sources; };
  orca-ai = final.orca;
  orca-ide = final.orca;
  skills-manager = final.callPackage ./skills-manager.nix { inherit sources; };

  # Electron 45 removed global Buffer from sandboxed preload scripts, breaking
  # r2modman 3.2.21 (`window.node.buffer.from` -> `Buffer.from` during mod downloads).
  # Re-wrap nixpkgs' prebuilt r2modman with electron_44 to avoid a ~590 MiB source rebuild.
  r2modman = final.symlinkJoin {
    name = "${prev.r2modman.pname}-${prev.r2modman.version}";
    paths = [ prev.r2modman ];
    nativeBuildInputs = [ final.makeWrapper ];
    postBuild = ''
      rm "$out/bin/r2modman"
      makeWrapper '${final.lib.getExe final.electron_44}' "$out/bin/r2modman" \
        --inherit-argv0 \
        --add-flags "${prev.r2modman}/share/r2modman" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
    '';
    inherit (prev.r2modman) meta;
  };
}
