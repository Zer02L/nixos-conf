{ inputs, pkgs, ... }:
{
  programs.umbriel = {
    enable = true;
    package = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
    portalPackage = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-umbriel;
  };
}
