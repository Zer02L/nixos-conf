# Управление секретами с помощью SOPS и Age в NixOS

Данное руководство содержит краткую инструкцию и обезличенные примеры работы с секретами.

---

## 1. Зачем нужен age и как он работает?

* **Что такое age:** `age` (Actually Good Encryption) — это быстрый и надёжный криптографический инструмент на замену GPG/PGP.
* **Используется ли он?** **Да, напрямую.**
  * `sops` отвечает за работу со структурой YAML/JSON (чтобы ключи оставались читаемыми, а значения шифровались).
  * `age` выступает **криптографическим ядром**, которое шифрует данные.
* **Как он связан с SSH:** `sops-nix` умеет использовать ваш стандартный ключ SSH (`~/.ssh/id_ed25519`) как ключ age.
  * Публичный ключ age генерируется из SSH-ключа командой `ssh-to-age < ~/.ssh/id_ed25519.pub`.
  * Этот публичный ключ записан в `.sops.yaml`.

---

## 2. Быстрые команды (Cheat Sheet)

```bash
# 1. Открыть secrets.yaml на редактирование
SOPS_AGE_SSH_KEY_PATHS=~/.ssh/id_ed25519 sops secrets.yaml

# 2. Посмотреть расшифрованное содержимое без редактирования
SOPS_AGE_SSH_KEY_PATHS=~/.ssh/id_ed25519 sops -d secrets.yaml

# 3. Перешифровать файл (если изменился .sops.yaml или добавлен новый ключ)
SOPS_AGE_SSH_KEY_PATHS=~/.ssh/id_ed25519 sops updatekeys secrets.yaml
```

---

## 3. Обезличенный пример файла `secrets.yaml`

При редактировании через `sops secrets.yaml` файл выглядит как обычный YAML:

```yaml
# Список IP-адресов серверов/прокси для исключения из Zapret
zapret_exclude_ips: |
  193.58.121.99/32

# Пример одиночного токена или пароля
api_token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Пример пароля пользователя или БД
db_password: "SuperSecretPassword123!"

# Пример закрытого ключа WireGuard / VPN
wireguard_private_key: "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE="
```

После сохранения `sops` автоматически зашифрует все значения.

---

## 4. Объявление секретов в NixOS (`modules/services/secrets.nix`)

```nix
{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${inputs.self}/secrets.yaml";
    age.sshKeyPaths = [ "/home/zerg/.ssh/id_ed25519" ];

    # Список секретов для расшифровки при загрузке:
    secrets = {
      # Исключение IP из Zapret (автоматически перезапускает сервис при изменении)
      "zapret_exclude_ips" = {
        mode = "0440";
        restartUnits = [ "zapret-discord-youtube.service" ];
      };

      # Секрет, доступный конкретному пользователю
      "api_token" = {
        owner = "zerg";
        mode = "0400";
      };

      # Секрет, монтируемый по кастомному пути
      "wireguard_private_key" = {
        path = "/etc/wireguard/private.key";
        mode = "0400";
      };
    };
  };
}
```

---

## 5. Использование в других модулях NixOS

Все расшифрованные файлы доступны по пути `config.sops.secrets.<имя_секрета>.path`:

```nix
{ config, pkgs, ... }:
{
  # Пример 1: чтение файла в systemd-сервисе
  systemd.services.example-service = {
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'cat ${config.sops.secrets.api_token.path}'";
    };
  };

  # Пример 2: передача переменной окружения из файла
  systemd.services.another-service = {
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.api_token.path;
    };
  };
}
```

---

## 6. Применение изменений

После любых правок в `.sops.yaml` или `secrets.yaml`:
```bash
git add .sops.yaml secrets.yaml
sudo nixos-rebuild switch --flake .#zerg
```

Проверить результат в оперативной памяти:
```bash
sudo cat /run/secrets/zapret_exclude_ips
```
