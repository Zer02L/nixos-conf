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

    # karousel — helper scripts for KWin tiling script
    ".local/bin/apply-karousel".source = mkOutOfStoreSymlink "${dotfilesDir}/karousel/apply.sh";
    ".local/bin/karousel-restart".source = mkOutOfStoreSymlink "${dotfilesDir}/karousel/karousel-restart";
    ".local/bin/plasma-restart".source = mkOutOfStoreSymlink "${dotfilesDir}/karousel/plasma-restart";
    # shellcheck-wrapper — strips --external-sources to prevent bash-lsp OOM
    ".local/bin/shellcheck-wrapper".source = mkOutOfStoreSymlink "${dotfilesDir}/zed/shellcheck-wrapper";

    # KDE Plasma 6 — stable user configs, live-editable via symlink
    ".config/kdeglobals".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/kdeglobals";
    ".config/kwinrc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/kwinrc";
    ".config/plasmashellrc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/plasmashellrc";
    ".config/plasmarc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/plasmarc";
    ".config/konsolerc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/konsolerc";
    ".config/dolphinrc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/dolphinrc";
    ".config/spectaclerc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/spectaclerc";
    ".config/krunnerrc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/krunnerrc";
    ".config/plasma-localerc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/plasma-localerc";
    ".config/kxkbrc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/kxkbrc";
    ".config/kded5rc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/kded5rc";
    ".config/kded6rc".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/kded6rc";
    # apply.sh — re-sync symlinks if Plasma overwrites them
    ".local/bin/apply-plasma".source = mkOutOfStoreSymlink "${dotfilesDir}/plasma/apply.sh";
  };

  # === Activation hooks ===
  # kwinrulesrc: KDE manages this file directly through GUI (NOT a symlink).
  # On every hm switch: seed from dotfiles if missing, or capture GUI changes back to dotfiles.
  home.activation.captureKwinRules = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    src="$HOME/nixos-conf/dotfiles/plasma/kwinrulesrc"
    dst="$HOME/.config/kwinrulesrc"
    if [ -L "$dst" ]; then
      # Former home-manager symlink → remove, replace with regular file from dotfiles
      rm -f "$dst"
      cp "$src" "$dst"
    elif [ -f "$dst" ]; then
      # Regular file (KDE owns it) → capture GUI changes back to dotfiles
      cp "$dst" "$src"
    else
      # No file yet → seed from dotfiles
      cp "$src" "$dst"
    fi
  '';

  # karousel: apply settings after every hm switch (auto-syncs to
  # dotfiles/plasma/kwinrc through the symlink, captures keybindings
  # into kglobalshortcutsrc)
  home.activation.applyKarousel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    apply_karousel="$HOME/nixos-conf/dotfiles/karousel/apply.sh"
    if [ -x "$apply_karousel" ]; then
      "$apply_karousel"
    fi
  '';
}
