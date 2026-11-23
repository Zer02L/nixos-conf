# Развертывание нового сервера / VPS

Пошаговое руководство по развертыванию нового сервера (VPS у любого провайдера: Hetzner, Selectel, Timeweb, Aeza, DigitalOcean, OVH или домашнего хоста).

---

## 1. Подготовка конфигурации хоста

1. **Скопируйте шаблон**:
   ```bash
   cp -r hosts/server-template hosts/my-server
   ```
2. **Настройте `hosts/my-server/default.nix`**:
   - Укажите имя: `networking.hostName = "my-server";`
   - Добавьте свой публичный SSH-ключ в `users.users.zerg.openssh.authorizedKeys.keys`.
3. **Проверьте диск в `hosts/my-server/disko.nix`**:
   - `/dev/vda` — для KVM / облачных VPS (Hetzner, Selectel, Timeweb и др.)
   - `/dev/sda` или `/dev/nvme0n1` — для выделенных серверов (Dedicated).
4. **Зарегистрируйте хост в `parts/nixos.nix`**:
   ```nix
   nixosConfigurations = {
     zerg = mkNixos "zerg";
     my-server = mkNixos {
       host = "my-server";
       system = "x86_64-linux"; # или "aarch64-linux" для ARM (Hetzner CAX, Oracle Cloud)
     };
   };
   ```

  > Шаблон по умолчанию не импортирует `hardware-configuration.nix` (строка закомментирована в `default.nix`). Если вы не используете `nixos-anywhere`, выполните `nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix` **на целевом сервере** в сессии установщика, затем `scp root@<IP>:/tmp/hardware-configuration.nix hosts/my-server/hardware-configuration.nix` со своего ПК и раскомментируйте импорт. Не генерируйте файл на машине администратора — получите не тот hardware-config.

---

## 2. Установка с нуля в 1 команду (`nixos-anywhere`)

Вам **не нужно** вручную монтировать ISO или ставить NixOS через панель хостинга. 
Закажите любой сервер со стандартным дистрибутивом (**Ubuntu** или **Debian**) и запустите со своего ПК.

**Prerequisite:** публичный SSH-ключ администратора должен быть уже в `authorized_keys` пользователя **root** на чистом VPS (панель хостинга / cloud-init). Ключ из `users.users.zerg.openssh.authorizedKeys.keys` в конфигурации подействует только после установки NixOS. Также нужны `git`, сеть и инструменты `sops`/`ssh-to-age` для раздела 3 (при необходимости: `nix shell nixpkgs#sops nixpkgs#ssh-to-age`).

```bash
git add -A
nix run github:nix-community/nixos-anywhere -- --flake .#my-server root@<IP_СЕРВЕРА>
```

`nixos-anywhere`:
1. Подключится по SSH к чистому серверу.
2. Загрузит минимальное окружение NixOS в оперативную память (kexec).
3. Автоматически разметит диск через ваш `disko.nix`.
4. Установит систему и перезагрузит сервер уже в вашу готовую NixOS.

---

## 3. Настройка секретов (SOPS + Age)

Сервер расшифровывает свои секреты с помощью своего хостового SSH-ключа (`/etc/ssh/ssh_host_ed25519_key`).

1. **Получите публичный age-ключ сервера**:
   ```bash
   ssh-keyscan <IP_СЕРВЕРА> 2>/dev/null | ssh-to-age
   ```
2. **Добавьте полученный ключ в `.sops.yaml`**:
   ```yaml
   creation_rules:
     - path_regex: secrets\.ya?ml$
       key_groups:
         - age:
             - age19pu6ks... # Ваш локальный ключ
             - age1server... # Полученный ключ нового сервера
   ```
3. **Перешифруйте секреты**:
   ```bash
   SOPS_AGE_SSH_KEY_PATHS=~/.ssh/id_ed25519 sops updatekeys secrets.yaml
   ```

---

## 4. Паттерны из Dreams of Code (Zero Open Ports & Native Systemd)

### А. Доступ только через Tailscale (Zero Open Ports)
В `hosts/my-server/default.nix`:
```nix
custom.tailscale.enable = true;
custom.server.access = "tailscale";
```
* Порт 22 снаружи **закрывается**. 
* SSH и администрирование доступны **только через приватный IP Tailscale** (`100.x.y.z`).
* Сканеры портов и боты из интернета не видят сервер вообще.

### Б. Публикация сервисов через Cloudflare Tunnel
Не открывая порты 80/443 наружу:
```nix
custom.cloudflared = {
  enable = true;
  tunnelId = "ВАШ_TUNNEL_UUID";
  ingress = {
    "api.example.com" = "http://127.0.0.1:8080";
  };
};
```

### В. Запуск сервисов нативно через Systemd (вместо Docker)
```nix
systemd.services.my-app = {
  description = "Backend App";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.my-app}/bin/my-app";
    DynamicUser = true;             # Безопасный временный пользователь
    StateDirectory = "my-app";      # Изолированная папка данных /var/lib/my-app
    Restart = "on-failure";
    LoadCredential = [
      "db_password:${config.sops.secrets.db_password.path}"
    ];
  };
};
```

---

## 5. Последующие обновления системы

После первоначальной установки деплойте обновления под пользователем `zerg`:

* Пользователь `zerg` должен входить в `wheel` (так настроено в `modules/users/zerg.nix`) и вводить пароль для `sudo`, либо у вас настроен passwordless sudo.
* Если включён `custom.server.access = "tailscale"` (раздел 4.А), публичный порт 22 закрыт — используйте **Tailscale-IP** (`100.x.y.z`), а не публичный IP.
* `root@<IP>` нужен только для первой установки через `nixos-anywhere`.

```bash
git add -A
nixos-rebuild switch --flake .#my-server --target-host zerg@<TAILSCALE_IP_ИЛИ_PUBLIC_IP> --use-remote-sudo
```
