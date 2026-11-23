# Руководство: Серверная инфраструктура, Multi-Site хостинг и T3 Code

Полное руководство по развертыванию серверов (EU и RU), безопасному удаленному использованию T3 Code, многосайтовому веб-хостингу на Caddy и запуску платформы **SiteCreator** с архитектурой **Fleet of Binaries** (изолированные клиентские сайты).

---

## 📑 Содержание
1. [Архитектура профилей: EU vs RU](#1-архитектура-профилей-eu-vs-ru)
2. [Развертывание чистого сервера в 1 команду (`nixos-anywhere`)](#2-развертывание-чистого-сервера-в-1-команду-nixos-anywhere)
3. [Управление секретами (SOPS + Age хостовый ключ)](#3-управление-секретами-sops--age-хостовый-ключ)
4. [T3 Code: Удаленная разработка в фоне](#4-t3-code-удаленная-разработка-в-фоне)
5. [Многосайтовый веб-хостинг на Caddy](#5-многосайтовый-веб-хостинг-на-caddy)
6. [Развертывание SiteCreator и клиентских сайтов (Fleet)](#6-развертывание-sitecreator-и-клиентских-сайтов-fleet)
7. [Шпаргалка команд управления](#7-шпаргалка-команд-управления)

---

## 1. Архитектура профилей: EU vs RU

Серверные конфигурации разделены по региональному признаку, учитывая особенности связности и законодательства:

```
profiles/
├── server.nix              # Базовый профиль: headless, bbr, fail2ban, openssh, sops-host-key, trusted-users
├── server/
│   ├── eu.nix              # Профиль EU: прямое подключение к AI (Claude/OpenAI), UTC, DoT (Cloudflare/Google)
│   └── ru.nix              # Профиль RU: Europe/Moscow, DoT (Yandex/Cloudflare), готовность к AI-прокси и Caddy
hosts/
├── server-eu/              # Готовый хост для европейского VPS (Hetzner, Aeza EU, Timeweb EU)
└── server-ru/              # Готовый хост для российского VPS (Selectel, Timeweb RU, Beget)
```

### Сравнение локаций:

| Параметр | Сервер в Европе (`server-eu`) | Сервер в России (`server-ru`) |
| :--- | :--- | :--- |
| **Доступ к LLM API** | Напрямую (Anthropic, OpenAI, Gemini) | Через исходящий туннель / прокси (`t3-server.proxy`) |
| **Сайты для пользователей РФ** | Возможны замедления / блокировки Cloudflare ECH | Прямой белый IP, пинг 5–20 мс, максимальная скорость |
| **Удаленное управление** | Tailscale / SSH | Tailscale или Cloudflare Tunnel |
| **Часовой пояс** | `UTC` | `Europe/Moscow` |

---

## 2. Развертывание чистого сервера в 1 команду (`nixos-anywhere`)

Вам **не нужно** вручную монтировать ISO в панели хостинга. Арендуйте любой VPS со стандартным дистрибутивом **Ubuntu** или **Debian** и запустите со своего ПК.

**Prerequisites:**

* Публичный SSH-ключ администратора уже находится в `authorized_keys` пользователя **root** на чистом VPS (через панель хостинга / cloud-init). Ключ в `users.users.zerg.openssh.authorizedKeys.keys` из конфигурации начнёт действовать **только после** установки NixOS — для первого подключения он не поможет.
* Рабочая сеть на ПК и сервере; инструменты `git`, `sops`, `ssh-to-age` доступны в окружении (при необходимости: `nix shell nixpkgs#sops nixpkgs#ssh-to-age`).
* Все файлы конфигурации зафиксированы в Git (см. раздел 7).

```bash
# 1. Добавьте свой публичный SSH-ключ в hosts/server-eu/default.nix или hosts/server-ru/default.nix
#    (для последующих входов под zerg):
# users.users.zerg.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3... your-key" ];

# 2. Установка в 1 команду (для сервера в Европе):
nix run github:nix-community/nixos-anywhere -- --flake .#server-eu root@<IP_СЕРВЕРА>

# Или для сервера в России:
nix run github:nix-community/nixos-anywhere -- --flake .#server-ru root@<IP_СЕРВЕРА>
```

`nixos-anywhere` автоматически подключится по SSH, загрузит минимальный kexec-образ NixOS в оперативную память, разметит диск через ваш `disko.nix`, установит систему и перезагрузит сервер в готовую NixOS.

---

## 3. Управление секретами (SOPS + Age хостовый ключ)

Сервер расшифровывает секреты собственным SSH-ключом хоста (`/etc/ssh/ssh_host_ed25519_key`), что исключает привязку к личным ключам разработчика.

1. **Получите публичный age-ключ созданного сервера**:
   ```bash
   ssh-keyscan <IP_СЕРВЕРА> 2>/dev/null | ssh-to-age
   # Пример вывода: age1serverabcdef123456...
   ```
2. **Добавьте ключ сервера в `.sops.yaml`**:
   ```yaml
   creation_rules:
     - path_regex: secrets\.ya?ml$
       key_groups:
         - age:
             - age19pu6ks... # Ваш локальный ключ ПК
             - age1server... # Ключ нового сервера
   ```
3. **Перешифруйте секреты**:
   ```bash
   SOPS_AGE_SSH_KEY_PATHS=~/.ssh/id_ed25519 sops updatekeys secrets.yaml
   ```

---

## 4. T3 Code: Удаленная разработка в фоне

На сервере развернут модуль [`modules/services/t3-server.nix`](../modules/services/t3-server.nix), позволяющий запускать AI-агента T3 Code как системный демон:

```nix
custom.services.t3-server = {
  enable = true;
  port = 3773;
  channel = "nightly"; # "stable" (по умолчанию) или "nightly" → pkgs.t3-cli-nightly

  # Для сервера в РФ: направляет запросы к Claude/OpenAI через внешний туннель
  # proxy = "http://127.0.0.1:1080";

  # openFirewall = false; # по умолчанию; порт открывается только для tailscale0
};
```

Опции модуля: `channel`, `package` (переопределяет бинарник), `port`, `host` (по умолчанию `0.0.0.0`), `proxy`, `openFirewall`. На клиентской машине канал T3 Code задаётся отдельно — `custom.t3code.channel` в `home/common/t3code.nix` (по умолчанию `nightly`).

### Преимущества:
* **Автономность 24/7**: агент работает в фоне даже при закрытой крышке ноутбука или выключенном домашнем ПК — `t3-server` это системный юнит (`systemd.services.t3-server`, `wantedBy = multi-user.target`, `Restart = on-failure`), а не пользовательский, поэтому `linger` на него не влияет.
* **Безопасность (Zero Open Ports)**: порт 3773 закрыт снаружи (`openFirewall = false`) и дополнительно разрешён только на интерфейсе `tailscale0`, если включён Tailscale. Подключение со смартфона или ПК происходит по адресу `http://100.x.y.z:3773`.

---

## 5. Многосайтовый веб-хостинг на Caddy

Модуль [`modules/services/caddy.nix`](../modules/services/caddy.nix) обеспечивает параллельную работу десятков сайтов на одном белом IP:

* **Авто-SSL**: Caddy сам получает и продлевает бесплатные сертификаты Let's Encrypt / ZeroSSL для каждого домена.
* **HTTP/3 (QUIC)**: открыт порт `443 UDP` для мгновенной загрузки на мобильных устройствах.
* **Гибридный файрвол**: при активации `custom.server.access = "tailscale"` порты SSH (22) и T3 Code (3773) закрываются снаружи, но порты 80 и 443 **автоматически остаются открытыми** для посетителей сайтов.

---

## 6. Развертывание SiteCreator и клиентских сайтов (Fleet)

Модуль [`modules/services/sitecraft.nix`](../modules/services/sitecraft.nix) реализует архитектуру **Fleet of Binaries** из документации SiteCreator.

> [!IMPORTANT]
> В репозитории `hosts/server-ru/default.nix` сервис объявлен с `enable = lib.mkDefault false`, а клиентские сайты в `fleet`/`staticSites` закомментированы как примеры. Приведённый ниже конфиг — иллюстрация: раскомментируйте нужные записи, задайте `enable = true`, создайте секреты в `secrets.yaml` и пересоберите систему.

**Prerequisites:**

* Исходники SiteCreator уже склонированы **на сервере** именно в `/home/zerg/Projects/web/SiteCreator` (значение по умолчанию `workingDirectory`); при другом пути переопределите `workingDirectory` и `executable`.
* На сервере доступны `git` и `make`, бинарник собран: `cd /home/zerg/Projects/web/SiteCreator && make build` (результат — `bin/server`, см. `executable`).
* Если задаёте `envSecret = "sitecraft_env"`, соответствующий ключ должен существовать в `secrets.yaml`, быть объявлен в `sops.secrets` и иметь формат env-файла `KEY=VALUE` (например, `TELEGRAM_BOT_TOKEN=...`).
* Домены клиентов уже направлены на IP сервера, иначе Caddy не сможет выпустить сертификаты.

При падении `make build` или смене пути бинарника остаточный юнит можно временно снять командой `sudo systemctl disable --now sitecraft` и вернуть предыдущий `executable` в конфигурации перед повторным `nixos-rebuild switch`.

### Конфигурация в `hosts/server-ru/default.nix` (пример):

```nix
custom.services.sitecraft = {
  enable = true;

  # Главная платформа конструктора:
  domain = "sitecreator.ru";
  wildcardDomain = "*.sitecreator.ru"; # Поддомены для создаваемых сайтов
  customDomains = true;                # Автоматический SSL на лету для собственных доменов клиентов

  # Секрет с токеном Telegram-бота из secrets.yaml:
  envSecret = "sitecraft_env";

  # =========================================================
  # Динамические сайты клиентов (Fleet of Binaries)
  # Потребление: ~25 МБ RAM на сайт, своя SQLite БД, свой бот
  # =========================================================
  fleet = {
    # Клиент 1 (Автосервис):
    auto-express = {
      domain = "auto-express.ru";
      port = 8091;
      # envSecret = "client_auto_env"; # токен Telegram-бота клиента
    };

    # Клиент 2 (Стоматология):
    dental-clinic = {
      domain = "dental-clinic.ru";
      port = 8092;
      # envSecret = "client_dental_env";
    };
  };

  # =========================================================
  # Статические сайты клиентов (0 МБ RAM)
  # =========================================================
  staticSites = {
    # Клиент 3 (Лендинг из ./fleet.sh export):
    notary-landing = {
      domain = "notary-moscow.ru";
      root = "/var/www/notary";
    };
  };
};
```

### Автоматические возможности для каждого клиента:
1. **Live-чат и Server-Sent Events (SSE)**: в Caddy автоматически прописан `flush_interval -1` для мгновенной доставки сообщений чата `/api/chat/sse`.
2. **Telegram Webhook**: Caddy отдает доверенный HTTPS на 443 порту, поэтому эндпоинт `/api/chat/telegram-webhook` без проблем принимает вебхуки от Telegram.
3. **Хранилище данных**: база SQLite изолирована в `/var/lib/sitecraft/fleet/<имя>/pb_data` и не стирается при деплоях.
4. **On-Demand TLS**: если клиент направляет свой домен на ваш сервер, Caddy валидирует его через эндпоинт `/api/check-domain` и автоматически выпускает SSL без правок конфига.

Полезные опции модуля: `port` (по умолчанию `8090`), `dataDir` (`/var/lib/sitecraft/pb_data`), `workingDirectory`, `executable`, `telegramProxy`. Имена юнитов: `sitecraft.service` для платформы и `sitecraft-fleet-<имя>.service` для каждого клиента.

---

## 7. Шпаргалка команд управления

### Деплой обновлений конфигурации с ПК
```bash
git add -A
nixos-rebuild switch --flake .#server-ru --target-host zerg@<IP_СЕРВЕРА> --use-remote-sudo
```

### Управление сервисами на сервере
```bash
# Статус главной платформы SiteCreator
systemctl status sitecraft

# Статус клиентского сайта из флота
systemctl status sitecraft-fleet-auto-express

# Логи Telegram-бота и бэкенда в реальном времени
journalctl -u sitecraft -f

# Логи Caddy (веб-запросы и выпуск SSL)
journalctl -u caddy -f

# Статус T3 Code демона
systemctl status t3-server
```

### Обновление кодовой базы SiteCreator
```bash
cd /home/zerg/Projects/web/SiteCreator
git pull
make build
sudo systemctl restart sitecraft
```
