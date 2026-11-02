# Добавление нового сервера

Инструкция по быстрому добавлению нового сервера (VPS или домашнего железа):

### 1. Создание хоста
1. Скопируйте шаблон:
   ```bash
   cp -r hosts/server-template hosts/my-server
   ```
2. В файле `hosts/my-server/default.nix` укажите:
   - `networking.hostName = "my-server";`
   - Добавьте свой публичный SSH-ключ в `users.users.zerg.openssh.authorizedKeys.keys`.
3. Сгенерируйте `hardware-configuration.nix` на сервере:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/my-server/hardware-configuration.nix
   ```
   И раскомментируйте импорт `./hardware-configuration.nix` в `default.nix`.
4. Проверьте диск в `hosts/my-server/disko.nix` (`/dev/vda` для KVM VPS, `/dev/sda` или `/dev/nvme0n1` для выделенных серверов).

### 2. Регистрация во Flake
В файле `parts/nixos.nix` в `nixosConfigurations` добавьте одну строчку:
```nix
nixosConfigurations = {
  zerg = mkNixos "zerg";
  my-server = mkNixos {
    host = "my-server";
    system = "x86_64-linux"; # или "aarch64-linux" для ARM серверов (Hetzner CAX, Oracle Cloud)
  };
};
```

### 3. Деплой на удаленный сервер
С локального компьютера:
```bash
git add -A
nixos-rebuild switch --flake .#my-server --target-host root@<IP_СЕРВЕРА> --use-remote-sudo
```
