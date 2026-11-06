# Russian VPS host configuration (e.g. Selectel, Timeweb RU, Beget, RuVDS)
# Multi-site architecture with SiteCraft Fleet of Binaries:
# 1. SiteCreator Engine & Master Panel.
# 2. Fleet Client Websites (isolated dynamic instances: 8091, 8092... ~25 MB RAM each).
# 3. Static Client Websites (SSG exported HTML/CSS, 0 MB RAM).
# 4. Private Zone: T3 Code headless server with outbound AI proxy, SSH on Tailscale only.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # Russian server profile (Europe/Moscow, anti-poisoning DoT, headless, hardened, sitecraft, caddy)
    ../../profiles/server/ru.nix

    # Storage partition layout via disko
    ./disko.nix
  ];

  networking.hostName = "server-ru";

  # UEFI bootloader
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # SSH public keys for remote administration
  users.users.zerg.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key"
  ];

  # =========================================================
  # 1. ПЛАТФОРМА SITECREATOR И КЛИЕНТСКИЕ САЙТЫ (FLEET)
  # =========================================================
  custom.services.sitecraft = {
    # Включите (true), когда будете готовы запустить сервис на сервере:
    enable = lib.mkDefault false;

    # Главный домен платформы конструктора:
    domain = lib.mkDefault "sitecreator.ru";

    # Поддомены для создаваемых сайтов (*.sitecreator.ru):
    # wildcardDomain = "*.sitecreator.ru";

    # Поддержка кастомных доменов клиентов (авто-выпуск SSL на лету через Caddy):
    # customDomains = true;

    # Токен Telegram-бота платформы:
    # envSecret = "sitecraft_env";

    # -------------------------------------------------------
    # А. Динамические сайты клиентов (Fleet of Binaries)
    # Каждый сайт изолирован: своя БД SQLite, своя админка PocketBase,
    # свой Telegram-бот для уведомлений, потребление всего ~25 МБ RAM.
    # -------------------------------------------------------
    fleet = {
      # Пример клиентского сайта 1 (Автосервис):
      # auto-express = {
      #   domain = "auto-express.ru";
      #   port = 8091;
      #   # envSecret = "client_auto_env"; # токен бота для заявок автосервиса
      # };

      # Пример клиентского сайта 2 (Стоматология):
      # dental-clinic = {
      #   domain = "dental-clinic.ru";
      #   port = 8092;
      #   # envSecret = "client_dental_env"; # токен бота для записи к врачу
      # };
    };

    # -------------------------------------------------------
    # Б. Статические сайты клиентов (Экспорт из ./fleet.sh export)
    # Плоские HTML/CSS/JS лендинги. 0 МБ RAM, мгновенная отдача через Caddy.
    # -------------------------------------------------------
    staticSites = {
      # legal-landing = {
      #   domain = "notary-moscow.ru";
      #   root = "/var/www/notary";
      # };
    };
  };

  # =========================================================
  # 2. ПРИВАТНАЯ ЗОНА: Удаленная разработка в T3 Code
  # =========================================================
  # T3 Code слушает порт 3773. Он изолирован от внешнего мира и доступен
  # только вам через Tailscale или локально. Запросы к AI идут через прокси.
  custom.services.t3-server = {
    enable = true;
    port = 3773;

    # Исходящий прокси для вызовов к Claude/OpenAI/Gemini в обход блокировок
    # proxy = "http://127.0.0.1:1080";
  };

  # =========================================================
  # 3. БЕЗОПАСНОСТЬ: Изоляция SSH
  # =========================================================
  custom.tailscale = {
    enable = true;
    tags = [ "tag:server" ];
  };

  # Закрываем SSH (порт 22) снаружи, оставляя доступ только по Tailscale.
  # При этом ВСЕ ваши публичные сайты на портах 80 и 443 остаются открытыми!
  # custom.server.access = "tailscale";
}
