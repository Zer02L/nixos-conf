# Karousel — scrollable tiling KWin script for KDE Plasma 6
# Niri-style vim keybindings, fully declarative via Nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  karouselConfig = {
    gapsOuterTop = 16;
    gapsOuterBottom = 16;
    gapsOuterLeft = 16;
    gapsOuterRight = 16;
    gapsInnerHorizontal = 8;
    gapsInnerVertical = 8;
    stackOffsetX = 8;
    stackOffsetY = 32;
    presetWidths = "33%, 50%, 67%";
    verticalResizeStep = 32;
    manualScrollStep = 200;
    scrollingLazy = true;
    scrollingCentered = true;
    scrollingGrouped = false;
    cursorFollowsFocus = true;
    tiledKeepBelow = true;
    floatingKeepAbove = false;
    untileOnDrag = true;
    offScreenOpacity = 100;
    stackColumnsByDefault = false;
    resizeNeighborColumn = false;
    gestureScroll = true;
    gestureScrollInvert = true;
    gestureScrollStep = 1920;
    skipSwitcher = false;
  };

  karouselKeybindings = {
    "karousel-focus-left" = "Meta+H";
    "karousel-focus-right" = "Meta+L";
    "karousel-focus-up" = "Meta+K";
    "karousel-focus-down" = "Meta+J";
    "karousel-focus-start" = "Meta+Home";
    "karousel-focus-end" = "Meta+End";

    "karousel-window-move-left" = "Meta+Shift+H";
    "karousel-window-move-right" = "Meta+Shift+L";
    "karousel-window-move-up" = "Meta+Shift+K";
    "karousel-window-move-down" = "Meta+Shift+J";
    "karousel-window-move-start" = "Meta+Shift+Home";
    "karousel-window-move-end" = "Meta+Shift+End";

    "karousel-column-move-left" = "Meta+Ctrl+Shift+H";
    "karousel-column-move-right" = "Meta+Ctrl+Shift+L";
    "karousel-column-move-start" = "Meta+Ctrl+Shift+Home";
    "karousel-column-move-end" = "Meta+Ctrl+Shift+End";

    "karousel-cycle-preset-widths" = "Meta+R";
    "karousel-cycle-preset-widths-reverse" = "Meta+Shift+R";
    "karousel-column-width-increase" = "Meta+Ctrl+Plus";
    "karousel-column-width-decrease" = "Meta+Ctrl+Minus";
    "karousel-columns-width-equalize" = "Meta+Ctrl+X";
    "karousel-columns-squeeze-left" = "Meta+Ctrl+H";
    "karousel-columns-squeeze-right" = "Meta+Ctrl+L";

    "karousel-window-toggle-floating" = "Meta+Shift+Space";
    "karousel-column-toggle-stacked" = "Meta+X";

    "karousel-grid-scroll-focused" = "Meta+Alt+C";
    "karousel-grid-scroll-left-column" = "Meta+Alt+H";
    "karousel-grid-scroll-right-column" = "Meta+Alt+L";
    "karousel-grid-scroll-left" = "Meta+Alt+PgUp";
    "karousel-grid-scroll-right" = "Meta+Alt+PgDown";
    "karousel-grid-scroll-start" = "Meta+Alt+Home";
    "karousel-grid-scroll-end" = "Meta+Alt+End";

    "karousel-column-move-to-next-desktop" = "Meta+Ctrl+PageDown";
    "karousel-column-move-to-previous-desktop" = "Meta+Ctrl+PageUp";

    "karousel-focus-1" = "Meta+1";
    "karousel-focus-2" = "Meta+2";
    "karousel-focus-3" = "Meta+3";
    "karousel-focus-4" = "Meta+4";
    "karousel-focus-5" = "Meta+5";
    "karousel-focus-6" = "Meta+6";
    "karousel-focus-7" = "Meta+7";
    "karousel-focus-8" = "Meta+8";
    "karousel-focus-9" = "Meta+9";

    "karousel-window-move-to-column-1" = "Meta+Shift+1";
    "karousel-window-move-to-column-2" = "Meta+Shift+2";
    "karousel-window-move-to-column-3" = "Meta+Shift+3";
    "karousel-window-move-to-column-4" = "Meta+Shift+4";
    "karousel-window-move-to-column-5" = "Meta+Shift+5";
    "karousel-window-move-to-column-6" = "Meta+Shift+6";
    "karousel-window-move-to-column-7" = "Meta+Shift+7";
    "karousel-window-move-to-column-8" = "Meta+Shift+8";
    "karousel-window-move-to-column-9" = "Meta+Shift+9";

    "karousel-column-move-to-column-1" = "Meta+Ctrl+Shift+1";
    "karousel-column-move-to-column-2" = "Meta+Ctrl+Shift+2";
    "karousel-column-move-to-column-3" = "Meta+Ctrl+Shift+3";
    "karousel-column-move-to-column-4" = "Meta+Ctrl+Shift+4";
    "karousel-column-move-to-column-5" = "Meta+Ctrl+Shift+5";
    "karousel-column-move-to-column-6" = "Meta+Ctrl+Shift+6";
    "karousel-column-move-to-column-7" = "Meta+Ctrl+Shift+7";
    "karousel-column-move-to-column-8" = "Meta+Ctrl+Shift+8";
    "karousel-column-move-to-column-9" = "Meta+Ctrl+Shift+9";
  };

  windowRulesJSON = builtins.toJSON [
    { class = "(org\\\\.kde\\\\.)?plasmashell"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?polkit-kde-authentication-agent-1"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?kded6"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?kcalc"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?kfind"; tile = true; }
    { class = "(org\\\\.kde\\\\.)?kruler"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?krunner"; tile = false; }
    { class = "(org\\\\.kde\\\\.)?yakuake"; tile = false; }
    { class = "steam"; caption = "Steam Big Picture Mode"; tile = false; }
    { class = "zoom"; caption = "Zoom Cloud Meetings|zoom|zoom <2>"; tile = false; }
    { class = "jetbrains-.*"; caption = "splash"; tile = false; }
  ];

  # Build section text — no JSON with parens goes into bash directly
  karouselSectionText = lib.concatStringsSep "\n" (
    [ "[Script-karousel]" ] ++
    (lib.mapAttrsToList (n: v: "${n}=${builtins.toJSON v}") karouselConfig) ++
    [ "windowRules=${windowRulesJSON}" "tiledDesktops=.*" ]
  );

  kwinSectionText = lib.concatStringsSep "\n" (
    [ "[kwin]" ] ++
    (lib.mapAttrsToList (n: v: "${n}=${v}") karouselKeybindings)
  );

  # Write sections to temp files so activation reads from file (no bash escaping issues)
  karouselSectionFile = pkgs.writeText "karousel-section" karouselSectionText;
  kwinSectionFile = pkgs.writeText "kwin-section" kwinSectionText;

in
{
  home.packages = [ pkgs.kdePackages.karousel ];

  home.activation.karouselSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    KWINRC="${config.home.homeDirectory}/.config/kwinrc"
    KGLOBAL="${config.home.homeDirectory}/.config/kglobalshortcutsrc"
    AWK="${pkgs.gawk}/bin/awk"
    SED="${pkgs.gnused}/bin/sed"

    # Remove stale symlinks from previous xdg.configFile usage
    [ -L "$KWINRC" ] && rm -f "$KWINRC"
    [ -L "$KGLOBAL" ] && rm -f "$KGLOBAL"

    touch "$KWINRC" "$KGLOBAL"
    chmod 644 "$KWINRC" "$KGLOBAL"

    # --- kwinrc: upsert [Script-karousel] ---
    $AWK -v newdata="$(cat ${karouselSectionFile})" '
      BEGIN { in_sec=0; done=0 }
      /^\[Script-karousel\]/ { in_sec=1; done=1; printf "%s\n", newdata; next }
      /^\[/ { if (in_sec && !done) { printf "%s\n", newdata; done=1 } in_sec=0 }
      { if (!in_sec) print }
      END { if (!done) printf "\n%s\n", newdata }
    ' "$KWINRC" > "$KWINRC.tmp" && mv "$KWINRC.tmp" "$KWINRC"

    # --- kglobalshortcutsrc: upsert [kwin] karousel keys ---
    $AWK -v newdata="$(cat ${kwinSectionFile})" '
      BEGIN { in_sec=0; done=0 }
      /^\[kwin\]/ { in_sec=1; done=1; printf "%s\n", newdata; next }
      /^\[/ { if (in_sec && !done) { printf "%s\n", newdata; done=1 } in_sec=0 }
      in_sec && /^karousel-/ { next }
      { if (!in_sec) print }
      END { if (!done) printf "\n%s\n", newdata }
    ' "$KGLOBAL" > "$KGLOBAL.tmp" && mv "$KGLOBAL.tmp" "$KGLOBAL"

    # --- enable plugin ---
    if ! grep -q 'karouselEnabled=true' "$KWINRC"; then
      if grep -q '^\[Plugins\]' "$KWINRC"; then
        $SED -i '/^\[Plugins\]/a karouselEnabled=true' "$KWINRC"
      else
        printf '\n[Plugins]\nkarouselEnabled=true\n' >> "$KWINRC"
      fi
    fi
  '';
}
