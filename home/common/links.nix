{ config, lib, pkgs, ... }: {
  home.file."Downloads".source = config.lib.file.mkOutOfStoreSymlink "/mnt/downloads";
  home.file.".local/share/Steam".source = config.lib.file.mkOutOfStoreSymlink "/mnt/steam";
}
