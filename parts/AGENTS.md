# parts/

## Purpose

Flake-parts modules that define top-level flake outputs. Each file is a composable part of the flake schema — `nixosConfigurations`, `homeConfigurations`, `devShells`, `formatter`.

## Ownership

All files here are owned by the system owner (zerg). These replace the monolithic `outputs` block that previously lived in `flake.nix`.

## Local Contracts

- Each file is a flake-parts module: `{ inputs, ... }: { flake.*, perSystem.* }`
- Paths to hosts and home configs use `../` relative to the part file (e.g. `../hosts/zerg`)
- Adding a new host: add it to `parts/nixos.nix` in the `nixosConfigurations` attrset
- Adding a new user: add it to `parts/home.nix` in the `homeConfigurations` attrset
- Shared NixOS modules stay in `modules/`; host-specific config stays in `hosts/<name>/`

## Work Guidance

- Keep parts focused: one concern per file (nixos, home, devshell, formatter)
- `perSystem` blocks run once per system architecture; avoid `perSystem` for system-agnostic flake outputs like `nixosConfigurations`
- Use `../hosts/${host}` for host paths — clean relative resolution from `parts/`

## Verification

```bash
nix flake check
nix eval .#nixosConfigurations.zerg.config.system.nixos.version
nix eval .#homeConfigurations."zerg@zerg".activationPackage
nix fmt
```
