# parts/

## Purpose

Flake-parts modules that define top-level flake outputs — `nixosConfigurations`, `homeConfigurations`, `nixosModules`, `homeManagerModules`, `devShells`, `formatter`. Каждый файл отвечает за один слой outputs.

## Ownership

All files here are owned by the system owner (zerg). These replace the monolithic `outputs` block that previously lived in `flake.nix`.

## Local Contracts

:- Each file is a flake-parts module: `{ inputs, ... }: { flake.*, perSystem.* }`
:- `parts/nixos.nix` exports `nixosModules.<name>` для каждого NixOS-модуля в `modules/` и `nixosModules.default` как aggregator
:- `parts/home.nix` exports `homeManagerModules.<name>` для каждого home-manager модуля в `home/common/` и `homeManagerModules.default` как aggregator
:- Hosts и home-конфиги импортируют модули через `inputs.self.nixosModules.default` / `inputs.self.homeManagerModules.default` (не относительными путями)
:- Добавление нового NixOS-модуля: создать файл в `modules/`, добавить в `parts/nixos.nix` + `modules/default.nix`
:- Добавление нового home-manager модуля: создать файл в `home/common/`, добавить в `parts/home.nix` + `home/common/default.nix`
:- Добавление нового хоста: добавить в `parts/nixos.nix` в `nixosConfigurations`
:- Shared NixOS modules stay in `modules/`; host-specific config stays in `hosts/<name>/`

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
