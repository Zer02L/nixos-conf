#!/usr/bin/env bash
# Apply karousel settings from dotfiles to KDE configs
# Makes it live: run after editing dotfiles/karousel/*.ini
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="/run/current-system/sw/bin:$PATH"
SETTINGS="$DOTDIR/karousel-settings.ini"
BINDINGS="$DOTDIR/karousel-keybindings.ini"

KWINRC="${HOME}/.config/kwinrc"
KGLOBAL="${HOME}/.config/kglobalshortcutsrc"
KHOTKEYS="${HOME}/.config/khotkeysrc"

AWK="${AWK:-awk}"
SED="${SED:-sed}"


# ---- 0. ensure symlinks (auto-heal if home-manager manages these paths) ----
# Prevents "file would be clobbered" on next home-manager switch
ensure_symlink() {
  local target="$1"
  local source="$2"
  # normalize: resolve .. to avoid path-string mismatches
  source="$(cd "$(dirname "$source")" && pwd)/$(basename "$source")"
  touch "$target" 2>/dev/null || true  # let readlink work
  local current
  current="$(readlink "$target" 2>/dev/null)" || true
  if [ -n "$current" ] && [ "$current" = "$source" ]; then
    return 0
  fi
  if [ ! -L "$target" ] && [ -f "$target" ]; then
    echo "  → $target: regular file → symlink to $source"
    cp "$target" "$target.bak.$(date +%s)" 2>/dev/null || true
  fi
  rm -f "$target"
  ln -sf "$source" "$target"
}

ensure_symlink "$KWINRC" "$DOTDIR/../plasma/kwinrc"
# Ensure files exist
touch "$KWINRC" "$KGLOBAL" "$KHOTKEYS"
chmod 644 "$KWINRC" "$KGLOBAL" "$KHOTKEYS"

# ---- 1. karousel settings -> kwinrc [Script-karousel] ----
# Remove existing [Script-karousel] section, append new one at EOF
$AWK '
  /^\[Script-karousel\]/ { in_sec = 1; next }
  /^\[/ { if (in_sec) in_sec = 0 }
  { if (!in_sec) print }
' "$KWINRC" > "$KWINRC.tmp"
# Strip trailing whitespace, ensure newline before appending
$SED -i -e '$a\' "$KWINRC.tmp"
# Append the settings (skip comment/blank lines)
$AWK '/^[^#]/ && !/^$/ { print }' "$SETTINGS" >> "$KWINRC.tmp"
cp "$KWINRC.tmp" "$KWINRC" && rm "$KWINRC.tmp"

# ---- 2. enable karousel plugin in [Plugins] ----
if ! grep -q '^karouselEnabled=true' "$KWINRC"; then
  if grep -q '^\[Plugins\]' "$KWINRC"; then
    $SED -i '/^\[Plugins\]/a karouselEnabled=true' "$KWINRC"
  else
    printf '\n[Plugins]\nkarouselEnabled=true\n' >> "$KWINRC"
  fi
fi

# ---- 3. karousel keybindings -> kglobalshortcutsrc [kwin] ----
# Remove karousel-* lines from [kwin], then insert fresh bindings
TMP_BIND=$(mktemp)
$AWK '/^[^#]/ && !/^$/ { print }' "$BINDINGS" > "$TMP_BIND"

$AWK '
  /^\[kwin\]/ { in_sec = 1; print; next }
  /^\[/      { if (in_sec) in_sec = 0 }
  in_sec && /^karousel-/ { next }
  { print }
' "$KGLOBAL" > "$KGLOBAL.tmp"

# Insert bindings after the [kwin] line (or create section)
if grep -q '^\[kwin\]' "$KGLOBAL.tmp"; then
  $AWK -v bindings="$TMP_BIND" '
    /^\[kwin\]/ { print; while ((getline line < bindings) > 0) print line; close(bindings); next }
    { print }
  ' "$KGLOBAL.tmp" > "${KGLOBAL}.tmp2" && mv "${KGLOBAL}.tmp2" "$KGLOBAL.tmp"
else
  printf '\n[kwin]\n' >> "$KGLOBAL.tmp"
  cat "$TMP_BIND" >> "$KGLOBAL.tmp"
fi
mv "$KGLOBAL.tmp" "$KGLOBAL"
rm -f "$TMP_BIND"

# ---- 4. khotkeys: Restart Karousel (Meta+Ctrl+Shift+R) ----
if ! grep -q "Name=Restart Karousel" "$KHOTKEYS" 2>/dev/null; then
  NEXT_IDX=$($AWK '
    /^\[Data_([0-9]+)\]/ {
      match($0, /^\[Data_([0-9]+)\]/, a)
      if (a[1] + 0 > max) max = a[1] + 0
    }
    END { print max + 1 }
  ' "$KHOTKEYS")

  if [ "$NEXT_IDX" -gt 0 ]; then
    $SED -i "s/^DataCount=.*/DataCount=$((NEXT_IDX + 1))/" "$KHOTKEYS"
  else
    printf '\n[Data]\nDataCount=1\n' >> "$KHOTKEYS"
    NEXT_IDX=0
  fi

  cat >> "$KHOTKEYS" << KHOTKEYS_ENTRY

[Data_${NEXT_IDX}]
Comment=Restart Karousel
Enabled=true
Name=Restart Karousel
Type=COMMAND

[Data_${NEXT_IDX}/Remap]
DataCount=0

[Data_${NEXT_IDX}/Triggers]
Count=1

[Data_${NEXT_IDX}/Triggers/0]
Key=Meta+Ctrl+Shift+R
Type=SHORTCUT

[Data_${NEXT_IDX}/Actions]
ActionsCount=1

[Data_${NEXT_IDX}/Actions/0]
CommandURL=karousel-restart
ExecutionMode=0
Remote=0
Startup=0
Type=COMMAND
KHOTKEYS_ENTRY
fi

# ---- 5. khotkeys: Restart Plasma (Meta+Ctrl+Shift+X) ----
if ! grep -q "Name=Restart Plasma" "$KHOTKEYS" 2>/dev/null; then
  NEXT_IDX=$($AWK '
    /^\[Data_([0-9]+)\]/ {
      match($0, /^\[Data_([0-9]+)\]/, a)
      if (a[1] + 0 > max) max = a[1] + 0
    }
    END { print max + 1 }
  ' "$KHOTKEYS")

  if [ "$NEXT_IDX" -gt 0 ]; then
    $SED -i "s/^DataCount=.*/DataCount=$((NEXT_IDX + 1))/" "$KHOTKEYS"
  else
    printf '\n[Data]\nDataCount=1\n' >> "$KHOTKEYS"
    NEXT_IDX=0
  fi

  cat >> "$KHOTKEYS" << KHOTKEYS_ENTRY

[Data_${NEXT_IDX}]
Comment=Restart Plasma
Enabled=true
Name=Restart Plasma
Type=COMMAND

[Data_${NEXT_IDX}/Remap]
DataCount=0

[Data_${NEXT_IDX}/Triggers]
Count=1

[Data_${NEXT_IDX}/Triggers/0]
Key=Meta+Ctrl+Shift+X
Type=SHORTCUT

[Data_${NEXT_IDX}/Actions]
ActionsCount=1

[Data_${NEXT_IDX}/Actions/0]
CommandURL=plasma-restart
ExecutionMode=0
Remote=0
Startup=0
Type=COMMAND
KHOTKEYS_ENTRY
fi

# ---- 6. reload ----
qdbus org.kde.khotkeys /khotkeys reconfigure 2>/dev/null || true
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "karousel: settings applied from $DOTDIR"
