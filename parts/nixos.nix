{ inputs, ... }:
let
  inherit (inputs) nixpkgs disko;
  inherit (inputs) nixpkgs-stable;

  system = "x86_64-linux";

  pkgs-stable = import nixpkgs-stable {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };

  mkNixos =
    args:
    let
      host = if builtins.isString args then args else args.host;
      system = if builtins.isAttrs args && args ? system then args.system else "x86_64-linux";
      hostPkgsStable = import nixpkgs-stable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        pkgs-stable = hostPkgsStable;
      };
      modules = [
        { nixpkgs.overlays = [ (import ../pkgs/default.nix) ]; }
        disko.nixosModules.disko
        ../hosts/${host}
      ];
    };

  # Individual NixOS modules — один источник истины
  modules = {
    system = import ../modules/system.nix;
    nix = import ../modules/nix.nix;
    fonts = import ../modules/fonts.nix;
    chromium = import ../modules/programs/chromium.nix;
    steam = import ../modules/programs/steam.nix;
    admin-tools = import ../modules/programs/admin-tools.nix;
    nsjail = import ../modules/programs/nsjail.nix;
    flclash = import ../modules/programs/flclash;
    wfhelper = import ../modules/programs/wfhelper;
    programs-common = import ../modules/programs/common.nix;
    nvidia = import ../modules/hardware/nvidia.nix;
    pipewire = import ../modules/services/pipewire.nix;
    zram = import ../modules/services/zram.nix;
    # zapret = import ../modules/services/zapret.nix;
    # zapret2 = import ../modules/services/zapret2.nix;
    cloudflare-warp = import ../modules/services/cloudflare-warp.nix;
    amneziawg = import ../modules/services/amneziawg.nix;
    vpn-timezone = import ../modules/services/vpn-timezone.nix;
    power = import ../modules/services/power.nix;
    postgresql = import ../modules/services/postgresql.nix;
    podman = import ../modules/services/podman.nix;
    comfyui = import ../modules/services/comfyui.nix;
    # omniroute = import ../modules/services/omniroute.nix;
    secrets = import ../modules/services/secrets.nix;
    networking = import ../modules/networking/base.nix;
    cloudflared = import ../modules/services/cloudflared.nix;
    tailscale = import ../modules/services/tailscale.nix;
    t3-server = import ../modules/services/t3-server.nix;
    caddy = import ../modules/services/caddy.nix;
    sitecraft = import ../modules/services/sitecraft.nix;
    desktop = import ../modules/desktop/foundation.nix;
    plasma = import ../modules/desktop/plasma.nix;
    users-zerg = import ../modules/users/zerg.nix;
    flatpak = import ../modules/services/flatpak.nix;

    happ = import ../modules/happ/happ-module.nix;
    #     firefox-librewolf-like = import ../home/common/firefox-librewolf-like.nix;
  };
in
{
  flake = {
    nixosConfigurations = {
      zerg = mkNixos "zerg";
      server-template = mkNixos "server-template";
      server-eu = mkNixos "server-eu";
      server-ru = mkNixos "server-ru";
    };
    # Individual + автогенерированный .default (импортирует всё)
    nixosModules = modules // {
      default = { ... }: {
        imports = builtins.attrValues modules;
      };
    };
  };
}
