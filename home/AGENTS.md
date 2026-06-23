# home/

## Purpose

Home-manager user configurations. Each subdirectory is a home-manager configuration target named after a user.

## Ownership

All files under this directory are user-level home-manager configuration owned by the system owner (zerg).

## Local Contracts

- `home/<user>/default.nix` is the entry point for each home-manager configuration
- Every user config imports `../common` for shared modules
- Flake outputs reference these as `homeConfigurations."<user>@<host>"`
- The `mkHome` function in `flake.nix` wraps each user config

## Work Guidance

- Shared modules live in `common/`; user-specific overrides go in `<user>/`
- When adding a new shared module: add to the `modules` attrset in `parts/home.nix` (as `homeManagerModules.<name>`)
  The `homeManagerModules.default` aggregator is auto-generated.
- When adding user-specific config: add to the user's `default.nix` imports or inline
- Dotfile symlinks are managed via `common/dotfiles.nix` using `mkOutOfStoreSymlink`
- Keep user dirs minimal — prefer common modules, override only what differs
- All home-manager changes deploy with `home-manager switch --flake .#zerg@zerg`

## Verification

```bash
home-manager switch --flake .#zerg@zerg
```

Dry build without switching: `home-manager build --flake .#zerg@zerg`

## Child DOX Index

| Path | Covers |
|---|---|
| `common/` | Shared home-manager modules: core packages, fish, git, tmux, ghostty, firefox, dotfile symlinks, git-hooks, zapret, karousel activation (apply.sh runs every switch), stylix (Stylix theming — Catppuccin Mocha) |
| `zerg/` | User `zerg` home config (imports common, sets username/homeDirectory) |
