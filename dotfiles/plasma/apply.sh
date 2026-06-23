#!/usr/bin/env bash
# Apply plasma settings from dotfiles to ~/.config/
# Run after editing dotfiles/plasma/* to re-sync if Plasma overwrote symlinks.
# Usage: ./apply.sh [--dry-run]
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${HOME}/.config"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SYMLINKED_FILES=(
  kdeglobals
  kwinrc
  plasmashellrc
  plasmarc
  konsolerc
  dolphinrc
  spectaclerc
  krunnerrc
  plasma-localerc
  kxkbrc
  kded5rc
  kded6rc
)

do_link() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD link: $src -> $dst"
    return
  fi
  # Remove if exists and is not a symlink to our dotfile
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst" 2>/dev/null || echo "")"
    if [ "$current" != "$src" ]; then
      rm -f "$dst"
    else
      # already correct
      return
    fi
  fi
  ln -sf "$src" "$dst"
  echo "linked: $dst -> $src"
}

echo "--- Plasma dotfiles sync ---"
for file in "${SYMLINKED_FILES[@]}"; do
  src="${DOTDIR}/${file}"
  dst="${CONFIG}/${file}"
  if [ -f "$src" ]; then
    do_link "$src" "$dst"
  else
    echo "WARN: $src not found, skipping"
  fi
done

echo "--- kwinrulesrc (regular file, not symlink) ---"
if [ "$DRY_RUN" = false ]; then
  cp "${DOTDIR}/kwinrulesrc" "${CONFIG}/kwinrulesrc"
  echo "seeded: ${CONFIG}/kwinrulesrc"
fi

# Reload Plasma configs
if [ "$DRY_RUN" = false ]; then
  # Tell KWin to reload
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
  # Tell Plasma shell to reload
  qdbus org.kde.plasmashell /PlasmaShell refreshShell 2>/dev/null || true
  echo "done: Plasma configs synced. You may need to re-login for some changes."
else
  echo "done: dry-run complete."
fi
