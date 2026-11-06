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
profiles/               — role profiles (core, server, server/eu, server/ru, workstation)
modules/                — system-level NixOS modules (services, programs, hardware, networking)
home/                   — home-manager user configs
dotfiles/               — symlinked dotfiles (nvim, fish, tmux, ghostty, etc.)
docs/                   — architectural guides & deployment manuals
```

## Documentation

- [Server & Web Deployment Guide](file:///home/zerg/nixos-conf/docs/SERVER_AND_WEB_DEPLOYMENT.md) — развертывание VPS в EU и RU, T3 Code, Caddy Multi-Site, SiteCreator Fleet
- [Adding a Server](file:///home/zerg/nixos-conf/docs/ADDING_SERVER.md) — пошаговое руководство по добавлению серверного хоста
- [SOPS Secrets Management](file:///home/zerg/nixos-conf/docs/SOPS.md) — управление зашифрованными секретами

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

All `.nix` files use `nixfmt` via the project formatter:
```bash
nix fmt
```
