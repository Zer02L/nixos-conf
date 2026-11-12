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
        t3-cli = pkgsWithCustom.t3-cli;
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
      };
    };
}
