{ inputs, ... }:
let
  overlay = import ../pkgs/default.nix;
in
{
  flake = {
    overlays.default = overlay;
  };

  perSystem =
    { system, ... }:
    let
      # Часть пакетов (antigravity-manager) с несвободной лицензией — без
      # allowUnfree `nix build .#<pkg>` падает на check-meta. В nixos- и
      # home-manager-конфигах allowUnfree задан отдельно, здесь — для вывода
      # flake `packages`.
      pkgsWithCustom = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };
    in
    {
      packages = {
        t3code = pkgsWithCustom.t3code;
        t3code-nightly = pkgsWithCustom.t3code-nightly;
        t3-cli = pkgsWithCustom.t3-cli;
        t3-cli-nightly = pkgsWithCustom.t3-cli-nightly;
        omp = pkgsWithCustom.omp;
        amethyst-mod-manager = pkgsWithCustom.amethyst-mod-manager;
        antigravity-manager = pkgsWithCustom.antigravity-manager;
        protonup-rs = pkgsWithCustom.protonup-rs;
        obscura = pkgsWithCustom.obscura;
        artcraft-launcher = pkgsWithCustom.artcraft-launcher;
        brave = pkgsWithCustom.brave;
        brave-origin = pkgsWithCustom.brave-origin;
        pi-coding-agent = pkgsWithCustom.pi-coding-agent;
        creabim = pkgsWithCustom.creabim;
        kiri = pkgsWithCustom.kiri;
        opencode = pkgsWithCustom.opencode;
        orca = pkgsWithCustom.orca;
        orca-ai = pkgsWithCustom.orca-ai;
        orca-ide = pkgsWithCustom.orca-ide;
        skills-manager = pkgsWithCustom.skills-manager;
        pandacode = pkgsWithCustom.pandacode;
      };
    };
}
