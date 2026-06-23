# modules/

## Purpose

NixOS system-level modules. Each file or subdirectory configures a discrete system concern. All modules are registered in `parts/nixos.nix` (as `nixosModules.<name>`) and re-exported via `nixosModules.default` (auto-generated aggregator).
## Ownership

All `.nix` files under this directory are system-level NixOS configuration owned by the system owner (zerg).

## Local Contracts

- Every module receives `{ config, lib, pkgs, ... }` and returns an attrset of NixOS options
- `parts/nixos.nix` is the single registry; new modules MUST be added to the `modules` attrset there
- Modules are grouped by concern into subdirectories: `services/`, `hardware/`, `programs/`, `networking/`, `desktop/`, `users/`
- Standalone files (`system.nix`, `nix.nix`, `fonts.nix`) remain at the top level when they don't belong to a group
## Work Guidance

- Add new services to `services/`, following existing patterns (see `omniroute.nix` for Docker containers, `pipewire.nix` for minimal service imports)
*19:- Add new programs to `programs/`; use `programs/common.nix` for shared packages, dedicated files for complex configs (`steam.nix`, `chromium.nix`, `dev-tools.nix`)
- Add hardware-specific config to `hardware/` (one file per device/driver)
- User definitions go in `users/`; one file per user
- Desktop environment modules go in `desktop/`; `foundation.nix` provides common DE dependencies (XWayland), individual files (e.g. `plasma.nix`) add specific DEs
- Keep module files focused — one concern per file; merge only when coupling is inherent
- Use `lib.mkDefault`, `lib.mkIf`, and `lib.mkMerge` for option composition
- Prefer upstream NixOS modules over manual `environment.systemPackages` when available

## Verification

```bash
sudo nixos-rebuild switch --flake .#zerg
```

If just validating syntax: `nix eval .#nixosConfigurations.zerg.config.system.build.toplevel --no-build` (or `nix build` without switching).

## Child DOX Index

| Path | Covers |
| `services/` | Docker containers, PipeWire, zram, power, PostgreSQL, zapret |
| `hardware/` | GPU drivers (Nvidia), hardware-specific kernel modules |
| `programs/` | System-wide program packages and program-specific options |
| `networking/` | DNS, firewall, DHCP, hostname |
| `desktop/` | Desktop environments (Plasma6/KDE) and DE-specific services (SDDM) |
| `users/` | System user accounts and groups |
