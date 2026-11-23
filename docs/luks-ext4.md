# LUKS + ext4 — схема диска

Новая схема после переустановки (2026-08). Причина перехода: повреждение btrfs-метаданных
(`parent transid verify failed`, см. старый `btrfs-recovery.md`) на фоне unsafe shutdowns.

## Схема разметки

`hosts/zerg/disko.nix`:

```
/dev/nvme0n1 (GPT)
├── ESP  1G   vfat  → /boot          (umask=0077)
└── luks 100%  LUKS2 "crypted"       (allowDiscards, пароль при загрузке)
    └── ext4 → /                     (discard, noatime)
```

- Одна ФС на весь LUKS-контейнер, **без subvolumes**.
- `/home`, `/nix`, `/mnt/{games,steam,downloads,db}` — обычные каталоги корневой ФС.
- Каталоги `/mnt/*` создаёт `systemd-tmpfiles` (`modules/system.nix`), symlink'и
  `~/Downloads` и `~/.local/share/Steam` — через `home/common/links.nix`.
- TRIM работает: `allowDiscards` в cryptsetup + опция монтирования `discard`.
- Пароль LUKS вводится интерактивно при загрузке (initrd: `boot.initrd.luks.devices.crypted`),
  ключевой файл не используется.

## Переустановка

**Prerequisites:** в installer ISO должны быть доступны `git` и сеть (для приватного репозитория — учётные данные/ключ SSH). Если сети нет, скопируйте репозиторий на флешку заранее или используйте предыдущую копию на диске.

1. Загрузиться с NixOS installer ISO.
2. Склонировать репозиторий, из каталога репозитория:
   ```bash
   sudo nix run github:nix-community/disko -- --mode disko hosts/zerg/disko.nix
   ```
   ⚠️ Пересоздаёт диск целиком — все данные будут уничтожены. Спросит пароль LUKS.
3. Установить систему:
   ```bash
   sudo nixos-install --flake .#zerg
   ```
   `hardware-configuration.nix` уже закоммичен в репозиторий, регенерировать не нужно.

## Проверка после установки

```bash
lsblk -f                      # nvme0n1p2 → crypted → ext4 /
mount | grep -E ' / | /boot'  # опции: discard,noatime
sudo cryptsetup status crypted # активный LUKS-контейнер, тип шифра xts-plain64
systemctl status fstrim.timer # TRIM по расписанию (включён в profiles/core.nix)
```

## Что устарело после перехода

- `btrfs-recovery.md` — btrfs больше нет, инструкции неактуальны (документ помечен как архивный).
- `btrfs-progs` в `modules/programs/admin-tools.nix` — уже закомментирован, из пакетов удалён.
