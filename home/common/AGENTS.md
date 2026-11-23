# home/common/

## Purpose

Shared home-manager modules imported by every user configuration. Defines packages, tool configs, and dotfile symlinks used across all users.

## Ownership

All `.nix` files here are shared home-manager module configuration owned by the system owner (zerg).

## Local Contracts

- New modules are added to the `modules` attrset in `parts/home.nix` (auto-loaded by `homeManagerModules.default`)
- `dotfiles.nix` manages the symlink map from `dotfiles/` into `~/.config/`
- `settings_hm.nix` sets user-level settings (session variables, stateVersion, nixpkgs config)
## Work Guidance

- Add new shared tool config: create `<tool>.nix`, add entry in `parts/home.nix`
- Keep modules single-concern; one tool per file
- `firefox-librewolf-like.nix` is complex (custom policies, UI tweaks) — read fully before editing
- `git-hooks.nix` defines pre-commit hooks — changes affect CI-equivalent local workflow
- Plasma settings (window rules, KWin, screen locker) live in `home/common/plasma.nix` (via plasma-manager); see `docs/KDE-DESKTOPS.md` for operational docs
- `karousel.nix` (KWin tiling) is currently commented out in `parts/home.nix` and not imported by the desktop profile — see `docs/KDE-DESKTOPS.md`
- `llm-agents-install.md` is a reference doc (not Nix config) for installing AI agent tools

## Verification

```bash
home-manager switch --flake .#zerg@zerg
```
