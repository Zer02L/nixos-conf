# nixos-conf

## Purpose

Personal NixOS and Home Manager configuration managed via Nix Flakes, `flake-parts`, `disko`, and `nvfetcher`.
Designed for multi-host scalability (desktop workstations, servers/VPS, laptops).

## Architecture

- **`flake.nix`**: Flake entrypoint using `flake-parts`.
- **`parts/`**: Flake modular components (`nixos.nix`, `home.nix`, `devshell.nix`, `formatter.nix`).
- **`profiles/`**: System roles and suites (`core.nix`, `server.nix`, `desktop.nix`, `workstation.nix`).
- **`hosts/`**: Host-specific definitions (hardware configuration, disk layouts via disko, host-specific services).
- **`modules/`**: Discrete system-level NixOS modules (services, programs, hardware, networking, desktop, users).
- **`home/`**: Home Manager configuration and user profiles.
- **`dotfiles/`**: Live configuration files for shells, editors, terminal emulators symlinked via `mkOutOfStoreSymlink`.
- **`pkgs/`**: Custom packages managed with `nvfetcher` and unified overlay.
- **`docs/`**: Operational documentation, guides, and runbooks.
- **`scripts/`**: Utility maintenance and daemon-interaction scripts.

## Key Contracts

1. **Host Immutability**: All machines import a profile from `profiles/` plus their own hardware and storage config.
2. **Evaluation Purity**: Flake outputs must evaluate without side effects (`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel`).
3. **Secrets Management**: Sensitive data is encrypted with `sops-nix` in `secrets.yaml` and loaded via systemd units.
4. **Package Updates**: External packages tracked via `nvfetcher.toml` and compiled in `_sources/`.
