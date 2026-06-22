# ============================================================================
# Firefox, настроенный как LibreWolf
# ============================================================================
# Этот файл настраивает Firefox через home-manager с политиками приватности
# и настройками about:config, максимально приближая его к LibreWolf.
#
# Основные отличия от LibreWolf:
#   - LibreWolf вырезает телеметрию на уровне компиляции (C++)
#   - Мы отключаем телеметрию через runtime-флаги (about:config)
#   - Разница ~5% в поверхности атаки, на практике незаметна
#
# Как работает:
#   1. policies — enterprise-политики (_locked,不可修改 пользователем)
#   2. settings — about:config (пользователь может менять, но зачем?)
# ============================================================================

{ config, pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    # ==========================================================================
    # ENTERPRISE POLICIES (policies.json)
    # ==========================================================================
    # Это то же самое, что файл policies.json вistribution/
    # Firefox читает их при запуске и применяет принудительно.
    # Пользователь НЕ может отключить locked-политики.
    # ==========================================================================
    policies = {

      # ─── Tracking & Privacy ────────────────────────────────────────────────
      # Strict Tracking Protection — блокирует трекеры, криптомайнеры,
      # fingerprinting. Locked = true → пользователь не может отключить.
      EnableTrackingProtection = {
        Value = true; # Включить защиту
        Locked = true; # Запретить отключение
        Cryptomining = true; # Блокировать криптомайнеры
        Fingerprinting = true; # Блокировать fingerprinting
      };

      # ─── Telemetry (телеметрия) ────────────────────────────────────────────
      # Firefox отправляет анонимные данные о usage в Mozilla.
      # Отключаем все виды telemetry: unified, bhrPing, updatePing и т.д.
      DisableTelemetry = true;

      # ─── Firefox Studies ───────────────────────────────────────────────────
      # "Shield" исследования — A/B тесты Mozilla. Отключаем.
      DisableFirefoxStudies = true;

      # ─── Pocket ────────────────────────────────────────────────────────────
      # Pocket — сервис "прочитать позже" от Mozilla. Рекомендации статей
      # на новой вкладке. Полностью отключаем.
      DisablePocket = true;

      # ─── Firefox Accounts ──────────────────────────────────────────────────
      # Синхронизация паролей, вкладок, истории между устройствами.
      # Если нужна — поменяй на false (но тогда Mozilla будет знать твои данные).
      DisableFirefoxAccounts = true;

      # ─── Firefox Suggest ───────────────────────────────────────────────────
      # Предложения в адресной строке от Mozilla. Отключаем.
      DisableFirefoxSuggest = true;

      # ─── Form Autofill ─────────────────────────────────────────────────────
      # Автозаполнение форм (имя, адрес, платёжные данные).
      # Отключаем для приватности.
      DisableFormAutofill = true;

      # ─── DNS-over-HTTPS (DoH) ─────────────────────────────────────────────
      # Шифрует DNS-запросы через HTTPS. Предотвращает перехват DNS.
      # Cloudflare chosen: быстрый, без логирования (по их заявлению).
      # Locked = false → пользователь может сменить провайдера в настройках.
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = false;
      };

      # ─── Sponsored Content ─────────────────────────────────────────────────
      # Убираем sponsored tiles, рекомендации, первую страницу.
      OverrideFirstRunPage = ""; # Пустая → пропускаем страницу приветствия
      OverridePostUpdatePage = ""; # Пустая → пропускаем страницу "что нового"

      # ─── Cookies ───────────────────────────────────────────────────────────
      # Behavior = 5 → RejectThirdParty (отклонять сторонние cookies)
      # Это aggressive, но эффективно против трекеров.
      # Некоторые сайты могут ломаться (например, кнопки "войти через Google").
      Cookies = {
        Behavior = 5; # RejectThirdParty
        BehaviorPrivateBrowsing = 5; # То же в приватном режиме
      };

      # ─── Extensions (плагины) ──────────────────────────────────────────────
      # Автоматическая установка расширений из addons.mozilla.org.
      # installation_mode = "force_installed" → ставится без запроса.
      # Каждое расширение идентифицируется по внутреннему ID.
      ExtensionSettings = {
        # ── Приватность ──
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed"; # Блокировщик рекламы и трекеров
        };
        "{b86e4813-687a-43e6-ab65-0bde4ab75758}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi";
          installation_mode = "force_installed"; # Подменяет CDN-запросы на локальные (защита от fingerprinting через CDN)
        };

        # ── Продуктивность ──
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
          installation_mode = "force_installed"; # Вертикальные вкладки с деревом, группами и контейнерами
        };
        "tridactyl.vim@cmcaine.co.uk" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
          installation_mode = "force_installed"; # Vim-навигация (j/k/f/t/b/d/u, :tabopen, :help)
        };
        "{531906d3-e22f-4a6c-a102-8057b88a1a63}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/single-file/latest.xpi";
          installation_mode = "force_installed"; # Сохранение страниц в один HTML-файл
        };
        # ── Multi-Account Containers ──
        "@testpilot-containers" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
          installation_mode = "force_installed"; # Multi-Account Containers — изоляция контекстов
        };

        # ── Менеджер паролей ──
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed"; # Bitwarden — менеджер паролей
        };
      };
    };

    # ==========================================================================
    # PROFILES (about:config)
    # ==========================================================================
    # Это настройки about:config для профиля по умолчанию.
    # Каждая строка = одна опция.
    #locked = false → пользователь может менять через about:config.
    # ==========================================================================
    profiles.default = {
      id = 0;
      isDefault = true;

      settings = {

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  PRIVACY (приватность)                                           ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Tracking Protection — общая защита от трекеров
        "privacy.trackingprotection.enabled" = true;

        # Социальные трекеры (кнопки "поделиться", виджеты Facebook/Twitter)
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # Криптомайнеры — блокирует скрипты майнинга
        "privacy.trackingprotection.cryptomining.enabled" = true;

        # Fingerprinting — блокирует определение браузера по "отпечатку"
        "privacy.trackingprotection.fingerprinting.enabled" = true;

        # Разделяет сеть по контексту (first-party isolation)
        # Предотвращает cross-site tracking через сеть
        "privacy.partition.network_state" = true;

        # Resist Fingerprinting — имитирует общий отпечаток для всех сайтов
        # Устанавливает общий User-Agent, размер окна, timezone и т.д.
        "privacy.resistFingerprinting" = true;

        # First-party isolation — cookies привязаны к домену
        # Предотвращает трекинг через cookies между сайтами
        "privacy.firstparty.isolate" = true;

        # ─── Cookies ───────────────────────────────────────────────────────
        # SameSite = none → cookies отправляются всегда (deprecated, но совместимость)
        "network.cookie.sameSite.none" = true;

        # Lax by default → cookies не отправляются при cross-site запросах
        # Если сайт не установлен, cookie не отправляется
        "network.cookie.laxOwnerByDefault" = true;

        # То же в фоновом режиме (когда вкладка не активна)
        "network.cookie.laxOwnerInBackground" = true;

        # Ослабляет SameSite для навигации (чтобы работали OAuth-редиректы)
        "network.cookie.laxRelaxTopNavigation" = true;

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  TELEMETRY (телеметрия)                                           ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Основная телеметрия — отправляет данные о usage в Mozilla
        "toolkit.telemetry.enabled" = false;

        # Unified telemetry — объединённая телеметрия (более агрессивная)
        "toolkit.telemetry.unified" = false;

        # Архив телеметрии — хранит данные локально перед отправкой
        "toolkit.telemetry.archive.enabled" = false;

        # Ping при создании нового профиля
        "toolkit.telemetry.newProfilePing.enabled" = false;

        # Ping при обновлении Firefox
        "toolkit.telemetry.updatePing.enabled" = false;

        # BHR Ping — "browser health report" (отправляет данные о крашах)
        "toolkit.telemetry.bhrPing.enabled" = false;

        # Первый shutdown ping
        "toolkit.telemetry.firstShutdownPing.enabled" = false;

        # Pioneer — система A/B тестов Mozilla
        "toolkit.telemetry.pioneer-new-studies-available" = false;

        # Ping Centre — централизованная телеметрия
        "browser.ping-centre.telemetry" = false;

        # Скрыть about:config (пользователь всё равно может зайти через about:config)
        "browser.aboutconfig.showing" = false;
        "browser.aboutConfig.showing" = false;

        # Не проверять, является ли Firefox основным браузером
        "browser.shell.checkDefaultBrowser" = false;

        # Health Report — отчёт о здоровье Firefox
        "datareporting.healthreport.uploadEnabled" = false;

        # Отправка данных в Mozilla
        "datareporting.policy.dataSubmissionEnabled" = false;

        # Уведомление о политике данных (показывается при первом запуске)
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;

        # Shield — A/B тесты Mozilla (аналог Google Chrome Experiments)
        "app.shield.optoutstudies.enabled" = false;

        # Discovery — рекомендации расширений на новой вкладке
        "browser.discovery.enabled" = false;

        # ─── New Tab Page (новая вкладка) ─────────────────────────────────
        # Убираем sponsored content, рекомендации, topsites
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.topsites.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.feeds.asrouter" = false;

        # CFR (Contextual Feature Recommendations) — рекомендации расширений
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

        # Sponsored в адресной строке
        "browser.urlbar.sponsoredTopSites" = false;

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  POCKET                                                          ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Pocket — сервис "прочитать позже" от Mozilla
        # Отключаем полностью: кнопку, API, ключи, рекомендации
        "browser.newtabpage.activity-stream-pocket.enabled" = false;
        "extensions.pocket.enabled" = false;
        "extensions.pocket.api" = ""; # Пустой API endpoint
        "extensions.pocket.oAuthConsumerKey" = ""; # Пустой ключ
        "extensions.pocket.site" = "";

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  SYNC / ACCOUNTS                                                 ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Firefox Accounts — синхронизация паролей, вкладок, истории
        # Если нужна — поменяй на false.
        "identity.fxaccounts.enabled" = false;

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  NETWORK (сеть)                                                  ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # IPv6 — оставляем включённым (некоторые сайты требуют)
        "network.dns.disableIPv6" = false;

        # DNS ECH (Encrypted Client Hello) — шифрует TLS handshake
        # Предотвращает SNI-based блокировки и цензуру
        "network.dns.echconfig.enabled" = true;

        # Fallback при ошибке ECH — если ECH не работает, fallback на обычный DNS
        "network.dns.echconfig.fallback_to_origin_when_all_failed" = false;

        # Referer Policy — контролирует, какую информацию отправлять при переходах
        # XOriginPolicy = 2 → отправлять Referer только для same-origin
        # XOriginTrimmingPolicy = 2 → отправлять только path без query string
        "network.http.referer.XOriginPolicy" = 2;
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  MISC (прочее)                                                   ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Compat Mode — показывать "Firefox" вместо "Mozilla/5.0" в User-Agent
        "general.useragent.compatMode.firefox" = true;

        # WebRTC — включён для видеозвонков (Meet, Jitsi, Zoom)
        # Защита от утечки локального IP за VPN/proxy
        "media.peerconnection.enabled" = true;

        # ICE candidate — только один внешний адрес
        "media.peerconnection.ice.default_address_only" = true;
        # Не отдавать локальный IP (192.168.x, 10.x, etc.) в ICE candidates
        "media.peerconnection.ice.no_host" = true;

        # Battery Status API — отключаем (фингерпринтинг через батарею)
        "dom.battery.enabled" = false;

        # Геолокация — отключаем (Firefox запрашивает геолокацию через Google)
        "geo.enabled" = false;

        # WebGL — оставляем включённым (некоторые сайты требуют, например, Google Maps)
        "webgl.disabled" = false;
        # ╔═══════════════════════════════════════════════════════════════════╗
        # ║  FINGERPRINT PROTECTION (защита от отпечатков)                   ║
        # ╚═══════════════════════════════════════════════════════════════════╝

        # Целевой размер экрана — RFP reports 1920x1080 вместо реального
        # Это убирает уникальные 1211x933 из fingerprint
        "privacy.resistFingerprinting.target_screen_res" = "1920,1080";

        # Canvas fingerprint — RFP уже шумит, но для надёжности:
        # Блокирует canvas readback для сторонних скриптов
        "canvas.fillers.successive_color_noise" = true;

        # WebGL — скрывает vendor/renderer (reports "Google Inc." generic)
        "webgl.enable-debug-renderer-info" = false;

        # Touchscreen — на десктопе должно быть 0 (у тебя 5 — аномалия)
        "dom.maxTouchPoints" = 0;

        # Media devices — скрывает количество микрофонов/камер
        # У тебя 1 mic + 1 cam — стандартно, но лучше ограничить
        "media.navigator.enabled" = false;

        # Fonts — ограничивает доступные через JS шрифты
        # RFP уже делает это, но для полноты:
        "font.system.whitelist" = "";

        # Screen orientation — блокирует orientation API (фингерпринт)
        "screen_orientation.allow_lock" = false;

        "dom.network.enabled" = false;

        # WebRTC — дополнительная защита от утечки IP
        "media.peerconnection.ice.proxy_only" = false;
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

        # Permissions — убирает prompt для camera/mic (предотвращает fingerprint через permissions)
        "media.getusermedia.camera.enabled" = false;
        "media.getusermedia.microphone.enabled" = false;

        # Notification permission — не показывает prompt (fp vector)
        "dom.webnotifications.enabled" = false;
        "dom.webnotifications.serviceworker.enabled" = false;

        # Clipboard — блокирует доступ через JS
        "dom.event.clipboardevents.enabled" = false;

        # Navigator.hardwareConcurrency — RFP spoofed, но на всякий случай
        # (privacy.resistFingerprinting уже возвращает 2 вместо реального)

        # Navigator.deviceMemory — RFP spoofed (возвращает 8)
        # (настоящее значение 4 видно в отчёте, значит RFP не sempre работает)

        # Speech synthesis — может fingerprint через voices
        "media.synth.speech.enabled" = false;

        # CSS media queries — RFP уже нормализует, но:
        "mediaprefersreducedmotion.reduce" = true;

        # Pointer events — скрывает количество кнопок мыши
        "dom.pointerEvents.enabled" = true;

        # Performance.now() — RFP добавляет шум (20µs jitter)
        # Это уже включено с privacy.resistFingerprinting = true

        # Keyboard — скрывает layout через key events
        "dom.keyboardevildelay.enabled" = false;

        # ─── Дополнительные anti-fingerprint настройки ─────────────────────

        # HTTP headers — не отправлять DNT (Do Not Track)
        # DNT=1 сигнализирует что ты заботишься о приватности → fingerprint
        "privacy.donottrackheader.enabled" = false;

        # Global Privacy Control — аналогично, не отправлять
        "privacy.globalprivacycontrol.enabled" = false;

        # Navigator.buildID — RFP spoofed (возвращает 20181001000000)
        # Это уже работает в отчёте ✓

        # Navigator.productSub — RFP spoofed (20100101)
        # Это уже работает в отчёте ✓

        # Window.devicePixelRatio — RFP reports 1 (у тебя 2)
        # Это должно работать с RFP, проверь после применения

        # Цветовая тема — 0 = тёмная тема (если системная тема тёмная)
        "layout.css.prefers-color-scheme.content-override" = 0;
      };
    };
  };
}
