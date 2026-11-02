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

## Interaction & Review Protocols

1. **Spec-First on Structural Changes**:
   - For non-trivial modifications (adding host profiles, modifying disk schemes via `disko`, redesigning network/firewall, changing `sops-nix` secret patterns, or major refactorings), do NOT jump directly into editing `.nix` files.
   - Formulate and present a brief architectural plan (affected modules, trade-offs, rollback strategy) and obtain user confirmation before writing code.

2. **Goldfish Documentation Verification**:
   - When creating or significantly updating operational runbooks, guides, or troubleshooting procedures in `docs/`, spawn an isolated subagent with zero conversational context.
   - Task the subagent with reviewing the guide strictly on its self-containment: identifying ambiguous commands, hidden prerequisites, missing failure recovery steps, or implicit assumptions.

