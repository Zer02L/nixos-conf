# dotfiles/

## Purpose

Raw dotfiles for terminal tools and editors. Symlinked into `~/.config/` by `home/common/dotfiles.nix` via `mkOutOfStoreSymlink`.

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
- `git/config` is the non-personal git config loaded via `include.path` from the real `~/.config/git/config`

## Verification

Symlinks resolve correctly: `ls -la ~/.config/<tool>` should point into this tree.
