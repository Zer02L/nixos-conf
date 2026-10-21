{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Системные настройки и активация программ (programs.*)
  programs.flclash.enable = lib.mkDefault true;
  programs.wfhelper.enable = lib.mkDefault true;
}
