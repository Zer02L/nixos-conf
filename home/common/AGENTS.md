# home/common/

## Purpose

Shared home-manager modules imported by every user configuration. Defines packages, tool configs, and dotfile symlinks used across all users.

## Ownership

All `.nix` files here are shared home-manager module configuration owned by the system owner (zerg).

## Local Contracts

- `default.nix` is the import hub; new modules MUST be added here
- Each file is a self-contained home-manager module receiving `{ config, lib, pkgs, ... }`
- `dotfiles.nix` manages the symlink map from `dotfiles/` into `~/.config/`
- `core.nix` sets core home-manager options (editor, stateVersion, etc.)

## Work Guidance

- Add new shared tool config: create `<tool>.nix`, add import in `default.nix`
- Keep modules single-concern; one tool per file
- `firefox-librewolf-like.nix` is complex (custom policies, UI tweaks) — read fully before editing
- `git-hooks.nix` defines pre-commit hooks — changes affect CI-equivalent local workflow
- `kwin-rules.nix` and `karousel.nix` manage KDE window management; see `KDE-DESKTOPS.md` in root for operational docs
- `llm-agents-install.md` is a reference doc (not Nix config) for installing AI agent tools

## Verification

```bash
home-manager switch --flake .#zerg@zerg
```
