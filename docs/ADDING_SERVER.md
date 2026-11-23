# Руководство по добавлению серверного хоста

В этой инструкции описан базовый процесс добавления нового сервера (VPS или локальной физической машины) в общую конфигурацию NixOS.

> [!TIP]
> Подробное руководство по развертыванию серверов в **Европе** и **России**, многосайтовому веб-хостингу (Caddy), удаленной разработке в **T3 Code** и запуску конструктора сайтов **SiteCreator (Fleet)** смотрите в [SERVER_AND_WEB_DEPLOYMENT.md](./SERVER_AND_WEB_DEPLOYMENT.md).

---

## 1. Архитектура ролей

Конфигурация разделена на профили в каталоге `profiles/`:

```
profiles/
├── core.nix         # База для ВСЕХ машин (Nix, сеть, zram, fstrim, admin-tools, zerg)
├── server.nix       # Базовый headless сервер: SSH, fail2ban, TCP BBR, sops-host-key
├── server/
│   ├── eu.nix       # Европейский сервер (Hetzner, Aeza EU): прямой AI, UTC, DoT
│   └── ru.nix       # Российский сервер (Selectel, Timeweb RU): DoT, AI-прокси, Caddy, SiteCraft
├── desktop.nix      # Графическая подсистема: Plasma 6, SDDM, PipeWire, шрифты, Flatpak
├── workstation.nix  # Рабочая станция: desktop, браузер, containers, vpn-suite
├── hardware/
│   └── nvidia.nix   # Аппаратный профиль GPU Nvidia
└── mixins/
    ├── ai.nix       # ComfyUI + PostgreSQL
    ├── gaming.nix   # Steam + wfhelper
    ├── containers.nix # Podman
    └── vpn-suite.nix  # AmneziaWG + WARP + FlClash + Happ + nsjail + Zapret2 + dynamic timezone
```

Сервер использует профиль `profiles/server.nix` (или региональные `profiles/server/eu.nix` / `profiles/server/ru.nix`), который исключает установку графических драйверов, дисплейных менеджеров, аудио-стека и пользовательских GUI-приложений.

---

## 2. Пошаговый процесс добавления сервера

### Шаг 1. Создание каталога хоста из шаблона

Скопируйте подготовленный шаблон `hosts/server-template` в каталог с именем вашего сервера (например, `vps` или `nas`):

```bash
cp -r hosts/server-template hosts/vps
```

### Шаг 2. Настройка `hosts/<имя_сервера>/default.nix`

Откройте `hosts/vps/default.nix` и укажите:
1. Имя хоста (`networking.hostName`).
2. Ваш публичный SSH-ключ для беспарольного доступа.
3. Дополнительные серверные службы по необходимости (Caddy, Cloudflared, PostgreSQL, Podman и т.д.).

Пример:
```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    # Подключение серверного профиля
    ../../profiles/server.nix

    # Разметка диска
    ./disko.nix

    # Специфика железа (сгенерированная на сервере)
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps";

  # Публичные SSH-ключи для доступа к пользователю zerg
  users.users.zerg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@workstation"
  ];

  # Серверные сервисы (пример):
  # services.cloudflared.enable = true;
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."example.com".extraConfig = ''
  #     reverse_proxy localhost:8080
  #   '';
  # };
}
```

### Шаг 3. Настройка диска (`disko.nix`)

В файле `hosts/vps/disko.nix` проверьте целевой блочный накопитель:
- `/dev/vda` — стандарт для большинства виртуальных машин (KVM, QEMU, Proxmox).
- `/dev/sda` — некоторые облачные провайдеры (Hetzner Cloud, DigitalOcean).
- `/dev/nvme0n1` — физические серверы с NVMe дисками.

### Шаг 4. Генерация `hardware-configuration.nix`

Если сервер уже запущен с установщика NixOS (Minimal ISO или kexec-образ), **выполните команду на целевом сервере** — на машине администратора этого относительного пути и hardware-конфигурации сервера нет:

```bash
# на сервере, в сессии установщика:
nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
# затем скопируйте файл на машину администратора (с своего ПК):
scp root@<IP_СЕРВЕРА>:/tmp/hardware-configuration.nix hosts/vps/hardware-configuration.nix
```

> [!WARNING]
> Не выполняйте `nixos-generate-config > hosts/vps/hardware-configuration.nix` на своём ПК — так вы получите конфиг рабочей станции вместо серверного.

В `hosts/server-template/default.nix` импорт по умолчанию **закомментирован** (`# ./hardware-configuration.nix`) — раскомментируйте его после копирования файла. Для `nixos-anywhere` генерировать hardware-config заранее не нужно.

---

## 3. Регистрация хоста во Flake

Откройте файл `parts/nixos.nix` и добавьте новый сервер в секцию `nixosConfigurations`:

```nix
# parts/nixos.nix
flake = {
  nixosConfigurations = {
    # Основная рабочая станция
    zerg = mkNixos "zerg";

    # Новый x86_64 сервер
    vps = mkNixos {
      host = "vps";
      system = "x86_64-linux";
    };

    # Или ARM-сервер (Hetzner CAX, Oracle Cloud Ampere A1, Raspberry Pi 5):
    # arm-server = mkNixos {
    #   host = "arm-server";
    #   system = "aarch64-linux";
    # };
  };
};
```

---

## 4. Развертывание и удаленный деплой

Все файлы конфигурации должны быть зафиксированы или проиндексированы Git:
```bash
git add hosts/vps parts/nixos.nix
```

### Первый деплой (установка на чистый сервер через nixos-anywhere)
Если сервер загружен в установщик NixOS:
```bash
nix run github:nix-community/nixos-anywhere -- --flake .#vps root@<IP_СЕРВЕРА>
```

### Регулярное обновление (с локального ПК по SSH)
Обновление сервера прямо с вашего компьютера без входа по SSH вручную:
```bash
nixos-rebuild switch --flake .#vps --target-host zerg@<IP_СЕРВЕРА> --use-remote-sudo
```

> Для первого подключения `nixos-anywhere` используется `root@<IP>` (ключ root'а должен быть добавлен в панели хостинга). После установки NixOS вход и деплой идут под `zerg`; пользователь `zerg` должен быть sudoer (настраивается в `modules/users/zerg.nix`). Если включён `custom.server.access = "tailscale"`, подключайтесь к Tailscale-IP сервера — публичный порт 22 закрыт.

### Полезный Alias для Fish shell
В `dotfiles/fish/config.fish` можно добавить функцию для быстрого деплоя:
```fish
function upvps --description 'Deploy config to VPS'
    git -C ~/nixos-conf add -A
    nixos-rebuild switch --flake ~/nixos-conf#vps --target-host zerg@$argv[1] --use-remote-sudo
end
```
Использование: `upvps 194.87.xxx.xxx`.

---

## 5. Home Manager на сервере (опционально)

Если на сервере требуется отдельный Home Manager для пользователя `zerg`:
Используйте терминальный профиль `home/profiles/cli.nix`:
```nix
# home/users/zerg-vps.nix
{ inputs, ... }: {
  imports = [
    ../profiles/cli.nix # fish, git, tmux, starship, nvim, yazi (без GUI)
  ];

  home.username = "zerg";
  home.homeDirectory = "/home/zerg";
}
```
Он обеспечит точно такое же привычное терминальное окружение (алиасы, плагины fish, starship prompt, конфиг neovim), как на рабочей станции, но без гигабайтов графических зависимостей.
