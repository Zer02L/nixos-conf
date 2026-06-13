{ config, lib, pkgs, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "zerg" "@wheel" ];
    accept-flake-config = true;
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1k81BUZQj4So8dCTCBj8otjY1IMwRNQFjT2V8M0g="
    ];
    trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # nh — Nix Helper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/zerg/nixos-conf";
  };
}
