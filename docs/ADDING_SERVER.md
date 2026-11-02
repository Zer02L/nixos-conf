# Руководство по добавлению серверного хоста

В этой инструкции описан процесс добавления нового сервера (VPS или локальной физической машины) в общую конфигурацию NixOS.

---

## 1. Архитектура ролей

Конфигурация разделена на профили в каталоге `profiles/`:

```
profiles/
├── core.nix         # База для ВСЕХ машин (Nix, сеть, zram, fstrim, admin-tools, zerg)
├── server.nix       # Headless сервер: SSH, fail2ban, TCP BBR, отключение GUI/звука
├── desktop.nix      # Графическая подсистема: Plasma 6, SDDM, PipeWire, шрифты, Flatpak
└── workstation.nix  # Полная рабочая станция: Nvidia, Steam, ComfyUI, Podman, VPN/прокси
```

Сервер использует профиль `profiles/server.nix`, который исключает установку графических драйверов, дисплейных менеджеров, аудио-стека и пользовательских GUI-приложений.

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

Если сервер уже запущен с установщика NixOS (Minimal ISO или kexec-образ):
```bash
nixos-generate-config --show-hardware-config > hosts/vps/hardware-configuration.nix
```
И убедитесь, что импорт `./hardware-configuration.nix` включен в `default.nix`.

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
nixos-rebuild switch --flake .#vps --target-host root@<IP_СЕРВЕРА> --use-remote-sudo
```

### Полезный Alias для Fish shell
В `dotfiles/fish/config.fish` можно добавить функцию для быстрого деплоя:
```fish
function upvps --description 'Deploy config to VPS'
    git -C ~/nixos-conf add -A
    nixos-rebuild switch --flake ~/nixos-conf#vps --target-host root@$argv[1] --use-remote-sudo
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
