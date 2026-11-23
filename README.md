# NixOS Configuration

This is my personal NixOS configuration managed with flakes + disko + home-manager.

## Project Structure

```
flake.nix               — flake entry point with inputs and outputs
hosts/
├── zerg/               — primary desktop workstation
├── server-eu/          — European VPS (Hetzner / Aeza EU, direct AI access, Tailscale)
├── server-ru/          — Russian VPS (Selectel / Timeweb RU, Multi-Site Caddy, SiteCreator Fleet)
└── server-template/    — base template for new servers
profiles/               — system roles (core, server, workstation), hardware profiles, and mixins (gaming, ai, containers, vpn-suite)
modules/                — system-level NixOS modules (services, programs, hardware, networking)
home/                   — home-manager user configs and shared modules
dotfiles/               — symlinked dotfiles (nvim, fish, tmux, ghostty, zapret, etc.)
pkgs/                   — custom packages via nvfetcher + unified overlay (`_sources/generated.nix`)
scripts/                — maintenance and daemon-interaction helpers
docs/                   — architectural guides & deployment manuals
```

## Documentation

**Servers & deployment**

- [Server & Web Deployment Guide](./docs/SERVER_AND_WEB_DEPLOYMENT.md) — развертывание VPS в EU и RU, T3 Code, Caddy Multi-Site, SiteCreator Fleet
- [Adding a Server](./docs/ADDING_SERVER.md) — пошаговое руководство по добавлению серверного хоста
- [Server template README](./hosts/server-template/README.md) — быстрый старт на новом VPS
- [SOPS Secrets Management](./docs/SOPS.md) — управление зашифрованными секретами
- [Disk layout: LUKS + ext4](./docs/luks-ext4.md) — текущая схема разметки рабочей станции

**Workstation**

- [Zapret2 Runbook](./docs/ZAPRET.md) — DPI-bypass: управление, списки, troubleshooting
- [Zapret2 Security Analysis](./SECURITY.md) — threat model и изоляция `nfqws2`
- [ComfyUI](./docs/COMFYUI.md) — rootless Podman + NVIDIA GPU
- [KDE Plasma desktops](./docs/KDE-DESKTOPS.md) — виртуальные столы и KWin rules
- [Neovim cheatsheet](./docs/CHEATSHEET.md) — ключевые привязки
- [Disk recovery (btrfs, archive)](./docs/btrfs-recovery.md) — устаревшая схема, только для исторических burst-дисков
- [AI agents install reference](./home/common/llm-agents-install.md) — ручная установка CLI-агентов

**Meta**

- [Git workflow](./docs/GIT_WORKFLOW.md) — GitHub Flow
- [OMP tools reference](./docs/omp-tools-reference.md) — встроенные инструменты OMP
- [Local agent tools](./docs/TOOLS.md) — краткая шпаргалка по инструментам агента

## Build & Deploy

```bash
# Build system
sudo nixos-rebuild switch --flake .#zerg

# Build home-manager
home-manager switch --flake .#zerg@zerg

# Just build (no switch)
nix build .#nixosConfigurations.zerg.config.system.build.toplevel
```

## Formatting

All `.nix` files use `nixpkgs-fmt` via the project formatter (`parts/formatter.nix`).
The wrapper defaults to `.` when no arguments are given, so both forms are safe:

```bash
nix fmt              # formats the whole repo
nix fmt -- .         # explicit target path (recommended in scripts)
```
