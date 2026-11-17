# profiles/

## Purpose

System roles, hardware drivers, and workload mixins. Profiles act as the composable bridge between discrete system modules (`modules/`) and concrete machine declarations (`hosts/`).

## Ownership

All files here are system-level NixOS configuration owned by the system owner (zerg).

## Architecture & Layers

1. **Core baseline (`core.nix`)**: Common foundation imported by all roles (workstations, servers, laptops). Configures Nix settings, base networking, zram, fstrim, admin tools, and user accounts.
2. **System Roles**: High-level roles defining machine type:
   - `desktop.nix`: Graphical foundation (Plasma 6, Wayland, Pipewire, fonts, Flatpak).
   - `workstation.nix`: Complete productivity environment (desktop + browser + containers + vpn suite). Hardware-agnostic.
   - `server.nix`: Headless server baseline (hardened SSH, fail2ban, TCP BBR, sops host key).
   - `server/eu.nix`: European VPS profile (direct AI API connectivity, UTC, DoT).
   - `server/ru.nix`: Russian VPS profile (anti-DPI DNS-over-TLS, SiteCraft platform, Caddy).
3. **Hardware Profiles (`hardware/`)**: Device and driver-specific configurations decoupled from roles:
   - `hardware/nvidia.nix`: Proprietary Nvidia GPU drivers and Wayland/CDI configuration.
4. **Workload Mixins (`mixins/`)**: Granular, optional capability suites composable per host:
   - `mixins/gaming.nix`: Steam, gaming controllers, and proton helpers.
   - `mixins/ai.nix`: ComfyUI rootless service and PostgreSQL dependencies.
   - `mixins/containers.nix`: Podman container runtime.
   - `mixins/vpn-suite.nix`: Anti-censorship and tunneling suite (AmneziaWG, Cloudflare WARP/Tunnel, FlClash, nsjail, happ, dynamic timezone).

## Local Contracts

- **Hardware Agnosticism**: Roles (such as `workstation.nix` or `desktop.nix`) MUST NEVER hardcode GPU/hardware drivers. Hardware drivers belong in `hardware/` or in the host directory.
- **Composable Lego Blocks**: Hosts compose capabilities by importing a role + hardware profile + optional mixins:
  ```nix
  imports = [
    ../../profiles/workstation.nix
    ../../profiles/hardware/nvidia.nix
    ../../profiles/mixins/gaming.nix
    ../../profiles/mixins/ai.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  ```
- **Option Defaults**: Profiles use `lib.mkDefault` for settings so that individual hosts can easily override them when needed.
- **Evaluation Purity**: Any profile addition or change must evaluate cleanly without side effects across all flake targets (`nixosConfigurations`).

## Work Guidance

- To add a new workload or tool suite: create a new mixin in `profiles/mixins/<name>.nix` and import into hosts that require it.
- To add a hardware driver (e.g. AMD GPU or Intel Wi-Fi): add to `profiles/hardware/<name>.nix`.
- Keep mixins focused on a single concern. Avoid circular dependencies between mixins.

## Verification

```bash
# Verify evaluation of desktop workstation
nix eval .#nixosConfigurations.zerg.config.system.build.toplevel.drvPath

# Verify evaluation of server hosts
nix eval .#nixosConfigurations.server-eu.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.server-ru.config.system.build.toplevel.drvPath
```
