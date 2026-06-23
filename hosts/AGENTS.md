# hosts/

## Purpose

Per-machine NixOS configurations. Each subdirectory is a host identified by its `networking.hostName`.

## Ownership

All files here are system-level NixOS host configuration owned by the system owner (zerg).

## Local Contracts

- `hosts/<name>/default.nix` is the entry point; imports `../../modules` plus host-specific files
- `parts/nixos.nix` defines `nixosConfigurations.<name>` using `mkNixos`; each host is added there
- Each host defines: `disko.nix` (disk layout), `hardware-configuration.nix` (generated hardware config), and `default.nix` (imports + hostName)

## Work Guidance

- To add a new host: create `hosts/<name>/` with `default.nix`, `disko.nix`, `hardware-configuration.nix`; add corresponding entry in `flake.nix` `nixosConfigurations`
- Never hand-edit `hardware-configuration.nix` — regenerate with `nixos-generate-config`
- `disko.nix` is declarative disk partitioning; test changes carefully — wrong values destroy data
- Host-specific modules go in the host directory; shared modules stay in `modules/`

## Verification

```bash
sudo nixos-rebuild switch --flake .#<name>
```

## Child DOX Index

| Path | Covers |
|---|---|
| `zerg/` | Main desktop: NVMe + LUKS + Btrfs, Nvidia GPU, KDE Plasma |
