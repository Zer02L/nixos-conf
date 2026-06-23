# dotfiles/

## Purpose

Raw dotfiles for terminal tools, editors, and KDE Plasma 6. Symlinked into `~/.config/` by `home/common/dotfiles.nix` via `mkOutOfStoreSymlink`.

## Ownership

All files here are user-level dotfiles owned by zerg. Managed as part of the NixOS configuration repo.

## Local Contracts

- Every subdirectory here maps 1:1 to a tool's config directory
- The symlink mapping is defined in `home/common/dotfiles.nix` — changes to symlink targets MUST be reflected there
- Files here are NOT in the Nix store — edits take effect immediately on the running system without rebuild
- The `.omp/` directory contains Oh My Posh agent data (skills, plugins, logs, databases) and is NOT dotfiles for deployment

## Work Guidance

- Add a new tool's config: create `dotfiles/<tool>/`, add symlink in `home/common/dotfiles.nix`
- Keep configs self-contained per tool directory
- Sensitive data (API keys, tokens) should NOT be committed; use `.gitignore`
- `nvim/` contains Neovim config with lazy.nvim; plugin versions tracked in `lazy-lock.json`
- `zed/` contains Zed editor config (`settings.json`) and a `shellcheck-wrapper` that strips `--external-sources` from ShellCheck to prevent OOM crashes
- `plasma/` contains KDE Plasma 6 user configs — stable settings and window rules (kdeglobals, kwinrc, kwinrulesrc, konsolerc, etc.)
- `karousel/` and `plasma/` come with `apply.sh` scripts; `~/.local/bin/apply-karousel` and `~/.local/bin/apply-plasma` re-sync if KDE overwrites symlinks
- Исключение: `kwinrulesrc` не симлинк — KDE управляет им напрямую, при `hm switch` изменения автоматически копируются в dotfiles через activation-хук
- `git/config` is the non-personal git config loaded via `include.path` from the real `~/.config/git/config`

## Verification

Symlinks resolve correctly: `ls -la ~/.config/<tool>` should point into this tree.
