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

> [!IMPORTANT]
> Добавление ключа в `secrets.yaml` — только первый шаг. Чтобы secret появился как файл в `/run/secrets/<имя>`, его нужно **дополнительно объявить в `sops.secrets.<имя>`** в NixOS-модуле (см. раздел 4). Например, Zapret2 ожидает `/run/secrets/zapret_private_hosts` и `/run/secrets/zapret_private_exclude` — одноимённые ключи должны быть и в YAML, и в `sops.secrets`. Ключ `zapret_exclude_ips` из примера выше сейчас ни одним модулем не потребляется.

---

## 4. Объявление секретов в NixOS (`modules/services/secrets.nix`)

Базовый модуль подключает `sops-nix` и задаёт значения по умолчанию через `lib.mkDefault`:

```nix
# modules/services/secrets.nix
{ config, lib, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = lib.mkDefault "${inputs.self}/secrets.yaml";
    # Рабочая станция расшифровывает личным SSH-ключом
    age.sshKeyPaths = lib.mkDefault [ "/home/zerg/.ssh/id_ed25519" ];

    # Списки секретов собираются из модулей через lib.mkMerge.
    # Сейчас секции для хоста zerg пуста; пример объявления:
    secrets = lib.mkMerge [
      (lib.mkIf (config.networking.hostName == "zerg") { })
      # {
      #   zapret_private_exclude = {
      #     mode = "0440";
      #     restartUnits = [ "nfqws2@default.service" ];
      #   };
      # }
    ];
  };
}
```

* **Серверы:** `profiles/server.nix` переопределяет ключ на хостовый: `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`.
* **Потребители секретов:** объявляют свои `sops.secrets.<name>` в своих модулях, например `modules/services/sitecraft.nix` для `envSecret` (с `restartUnits = [ "sitecraft.service" ]`), а Zapret2 читает `/run/secrets/zapret_private_hosts` и `/run/secrets/zapret_private_exclude` в `preStart` (см. [ZAPRET.md](ZAPRET.md)).
* Доступные атрибуты секрета: `owner`, `mode`, `path`, `restartUnits` — как в примерах ниже.

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

После любых правок в `.sops.yaml`, `secrets.yaml` **или** объявлении нового `sops.secrets.<name>`:
```bash
git add .sops.yaml secrets.yaml
sudo nixos-rebuild switch --flake .#zerg
```

Проверить результат в оперативной памяти можно только для секретов, которые реально объявлены в `sops.secrets`. Например, после добавления объявления `zapret_private_exclude` (см. раздел 4):
```bash
sudo ls -l /run/secrets/zapret_private_exclude
sudo cat /run/secrets/zapret_private_exclude
```

> Если файла нет — проверьте, что ключ существует в `secrets.yaml` **и** объявлен в `sops.secrets`, и что пересборка была успешной. Само наличие ключа в YAML файл не создаёт.
