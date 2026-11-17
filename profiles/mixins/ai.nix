# AI / Machine Learning mixin: ComfyUI and local AI pipeline services
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/services/comfyui.nix
    ../../modules/services/postgresql.nix
  ];
}
