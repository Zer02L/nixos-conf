{ config, lib, pkgs, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/nixos-conf/dotfiles";
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home.file = {
    # starship
    ".config/starship/starship.toml".source = mkOutOfStoreSymlink "${dotfilesDir}/starship/starship.toml";

    # btop
    ".config/btop/btop.conf".source = mkOutOfStoreSymlink "${dotfilesDir}/btop/btop.conf";

    # mpv
    ".config/mpv/mpv.conf".source = mkOutOfStoreSymlink "${dotfilesDir}/mpv/mpv.conf";

    # yt-dlp
    ".config/yt-dlp/config".source = mkOutOfStoreSymlink "${dotfilesDir}/yt-dlp/config";

    # yazi — theme and keymap are separate files, yazi.toml too
    ".config/yazi/yazi.toml".source = mkOutOfStoreSymlink "${dotfilesDir}/yazi/yazi.toml";
    ".config/yazi/keymap.toml".source = mkOutOfStoreSymlink "${dotfilesDir}/yazi/keymap.toml";
    ".config/yazi/theme.toml".source = mkOutOfStoreSymlink "${dotfilesDir}/yazi/theme.toml";

    # git — non-personal config loaded via include.path
    ".config/git/config-dotfiles".source = mkOutOfStoreSymlink "${dotfilesDir}/git/config";

    # ghostty
    ".config/ghostty/config".source = mkOutOfStoreSymlink "${dotfilesDir}/ghostty/config";

    # nvim
    ".config/nvim".source = mkOutOfStoreSymlink "${dotfilesDir}/nvim";

    # zed
    ".config/zed/settings.json".source = mkOutOfStoreSymlink "${dotfilesDir}/zed/settings.json";

    # omp config
    ".omp".source = mkOutOfStoreSymlink "${dotfilesDir}/.omp";

    # shellcheck-wrapper — strips --external-sources to prevent bash-lsp OOM
    ".local/bin/shellcheck-wrapper".source = mkOutOfStoreSymlink "${dotfilesDir}/zed/shellcheck-wrapper";

  };
}
