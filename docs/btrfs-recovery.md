# Btrfs Recovery — parent transid verify failed

## Симптомы

- `Input/output error` при доступе к файлам в `/nix/store`
- `nix-store --verify` падает на множестве `.drv` с `Input/output error`
- `journalctl` / `dmesg` показывает:

```
BTRFS error (device dm-0): parent transid verify failed on logical <addr> mirror 1 wanted <N> found <M>

```

- Файловая система переведена ядром в `ro` (флаг `M` в dmesg)

## Диагноз

- Причина: **unsafe shutdown** (708 count на данном SSD).
- Единственный битый extent buffer на обоих зеркалах — обрыв записи транзакции.
- **Диск здоров** (SMART PASSED, Reallocated 0, Bad Blocks 0).
- **Данные целы**, повреждены только btrfs-метаданные.

---

## Восстановление

### A) Через Live USB (рекомендуется)

1. Загрузиться с **NixOS installation ISO** (или любого Linux live USB с btrfs-progs).
2. Открыть LUKS:
   ```bash
   sudo -i
   cryptsetup open /dev/sda2 crypted
   ```
3. Проверить ФС (readonly):
   ```bash
   btrfs check --readonly /dev/mapper/crypted
   ```
4. Починить:
   ```bash
   btrfs check --repair /dev/mapper/crypted
   ```
5. Перезагрузиться.
6. После загрузки — проверить и перестроить store:
   ```bash
   nix-store --verify --check-contents --repair
   ```

### B) Через ядерный rescue-параметр (быстрее, без live USB)

1. При загрузке в **GRUB** нажать `e` на нужном entry, дописать к строке `linux`:
   ```
   btrfs.rescue=ignorebadroots
   ```
2. `Ctrl+X` для загрузки.
3. После загрузки — примонтировать rw:
   ```bash
   sudo mount -o remount,rw /nix/store
   ```
4. Запустить scrub (восстанавливает метаданные из здоровых копий):
   ```bash
   sudo btrfs scrub start /nix/store
   ```
   Дождаться завершения:
   ```bash
   sudo btrfs scrub status /nix/store
   ```
5. Проверить store:
   ```bash
   nix-store --verify --check-contents --repair
   ```
6. Перезагрузиться **без** rescue-параметра.

### C) zero-log (без перезагрузки, 20% шанс)

Если нет возможности перезагрузиться — попробовать очистить лог транзакции:

```bash
sudo btrfs rescue zero-log --force /dev/mapper/crypted
sudo mount -o remount,rw /nix/store
sudo btrfs scrub start /nix/store
```

---

## После восстановления

1. **Проверить store:**
   ```bash
   nix-store --verify --check-contents --repair
   ```
2. **Сделать snapshot** метаданных btrfs (опционально):
   ```bash
   sudo btrfs subvolume snapshot /nix/store /nix/store-snapshot
   ```
3. **Заменить диск при первой возможности.** Хотя SMART чист, 708 unsafe shutdowns — признак, что система нестабильна.

---

## Диагностические команды

```bash
# Состояние диска
sudo smartctl -x /dev/sda

# ФС
sudo btrfs filesystem show /dev/mapper/crypted
sudo btrfs device stats /dev/mapper/crypted
sudo btrfs filesystem usage /dev/mapper/crypted

# dmesg
sudo dmesg | grep -iE 'btrfs|i/o error|buffer I/O' | tail -40

# Состояние монтирования
mount | grep /nix/store
```

---

## Предотвращение

- **Не выключать питание без clean shutdown.**
- Проверить, не сбрасывается ли система (kernel panic, OOM, watchdog).
- Рассмотреть `sync`/`fstrim` перед выключением на SSD с Phison-контроллером.
- При частых крашах — настроить `kernel.panic` и `NixOS`-опции для принудительной синхронизации.
