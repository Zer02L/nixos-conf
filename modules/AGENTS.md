# modules/

## Purpose

NixOS system-level modules imported by `modules/default.nix`. Each file or subdirectory configures a discrete system concern.

## Ownership

All `.nix` files under this directory are system-level NixOS configuration owned by the system owner (zerg).

## Local Contracts

- Every module receives `{ config, lib, pkgs, ... }` and returns an attrset of NixOS options
- `modules/default.nix` is the single import hub; new modules MUST be added here to take effect
- Modules are grouped by concern into subdirectories: `services/`, `hardware/`, `programs/`, `networking/`, `users/`
- Standalone files (`system.nix`, `nix.nix`, `fonts.nix`) remain at the top level when they don't belong to a group

## Work Guidance

- Add new services to `services/`, following existing patterns (see `omniroute.nix` for Docker containers, `pipewire.nix` for minimal service imports)
- Add new programs to `programs/`; use `programs/common.nix` for shared packages, dedicated files for complex configs (`steam.nix`, `brave.nix`, `dev-tools.nix`)
- Add hardware-specific config to `hardware/` (one file per device/driver)
- User definitions go in `users/`; one file per user
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
|---|---|
| `services/` | Docker containers, PipeWire, display manager, zram, power, PostgreSQL, zapret |
| `hardware/` | GPU drivers (Nvidia), hardware-specific kernel modules |
| `programs/` | System-wide program packages and program-specific options |
| `networking/` | DNS, firewall, DHCP, hostname |
| `users/` | System user accounts and groups |
