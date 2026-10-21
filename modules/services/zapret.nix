{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.zapret-discord-youtube.nixosModules.withTestTools
  ];

  services.zapret-discord-youtube = {
    enable = false;

    # 1. Меняем стратегию на "general(ALT12)"
    # ALT12 использует hostfakesplit + ts для Google/YouTube и двойной fake stun/quic для Discord
    configName = "general(ALT9)";

    # 2. GameFilter — оставляем "all" (включает обработку UDP и TCP для списков)
    gameFilter = "all";

    # 3. Домены для обхода (list-general.txt)
    listGeneral = [
      "github.com"
      "api.github.com"
      "steamcommunity.com"
      "store.steampowered.com"
      "api.steampowered.com"
      "steamcdn-a.akamaihd.net"
      "steamuserimages-a.akamaihd.net"
      "steamloopback.host"

      # --- ДОМЕНЫ ИГРЫ И AWS GAMELIFT (Критично для Darktide) ---
      "atoma.cloud"
      "bsp-auth-prod.atoma.cloud"
      "bsp-td-prod.atoma.cloud"
      "accounts.atoma.cloud"
      "darktide.games"
      "fatsharkgames.com"
      "fatshark.se"
      "playdarktide.com"
      "amazonaws.com"
      "awsstatic.com"
      "cloudfront.net"
      "s3.amazonaws.com"
      "signin.aws.amazon.com"
      "console.aws.a2z.com"
      "awsapps.com"
      "sso.amazonaws.com"
      "gamelift.us-east-1.amazonaws.com"
      "gamelift.eu-central-1.amazonaws.com"

      # --- AMAZON ---
      "amazon.com"
      "media-amazon.com"
      "ssl-images-amazon.com"
      "a2z.com"

      # --- CLOUDFLARE И WARP ---
      "deadbydaylight.com"
      "deadbydaylight.fandom.com"
      "argotunnel.com"
      "cfargotunnel.com"
      "cfl.re"
      "cloudflare-dns.com"
      "cloudflare-ech.com"
      "cloudflare-esni.com"
      "cloudflare-gateway.com"
      "cloudflare-quic.com"
      "cloudflare.com"
      "cloudflare.net"
      "cloudflare.tv"
      "cloudflareaccess.com"
      "cloudflareapps.com"
      "cloudflarebolt.com"
      "cloudflareclient.com"
      "cloudflareinsights.com"
      "cloudflareok.com"
      "cloudflarepartners.com"
      "cloudflareportal.com"
      "cloudflarepreview.com"
      "cloudflareresolve.com"
      "cloudflaressl.com"
      "cloudflarestatus.com"
      "cloudflarestorage.com"
      "cloudflarestream.com"
      "cloudflaretest.com"
      "cloudflarewarp.com"
      "every1dns.net"
      "isbgpsafeyet.com"
      "one.one.one.one"
      "one.one.one"
      "pacloudflare.com"
      "pages.dev"
      "trycloudflare.com"
      "videodelivery.net"
      "warp.plus"
      "workers.dev"
    ];

    # 4. IP-подсети Cloudflare (ipset-all.txt)
    # Попадают в ipset-all для перехвата трафика по IP
    ipsetAll = [
      "103.21.244.0/22"
      "103.22.200.0/22"
      "103.31.4.0/22"
      "104.16.0.0/13"
      "104.24.0.0/14"
      "108.162.192.0/18"
      "131.0.72.0/22"
      "141.101.64.0/18"
      "162.158.0.0/15"
      "172.64.0.0/13"
      "173.245.48.0/20"
      "188.114.96.0/20"
      "190.93.240.0/20"
      "197.234.240.0/22"
      "198.41.128.0/17"
    ];

    # Приватные IP-адреса VPS/прокси вынесены в sops/age (secrets.yaml -> zapret_exclude_ips)
    # и динамически подгружаются в nozapret / iptables через postStart сервиса zapret-discord-youtube.
    ipsetExclude = [ ];

    listExclude = [ ];

    # 5. Специфичные параметры (nfqwsAppend)
    nfqwsAppend = [ ];

    # Блок extraConfigs нам не нужен, удаляем его, чтобы избежать конфликтов.
    extraConfigs = { };
  };

  # Исключаем виртуальные интерфейсы FlClash / Happ / sing-box и IP из sops/age из перехвата Zapret
  systemd.services.zapret-discord-youtube = lib.mkIf config.services.zapret-discord-youtube.enable {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    postStart = ''
      # Проверка существования правила перед добавлением (защита от дублирования при рестартах)
      ${pkgs.iptables}/bin/iptables -C OUTPUT -o tun+ -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/iptables -I OUTPUT 1 -o tun+ -j ACCEPT
      ${pkgs.iptables}/bin/iptables -C OUTPUT -o clash+ -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/iptables -I OUTPUT 1 -o clash+ -j ACCEPT
      ${pkgs.iptables}/bin/iptables -C OUTPUT -o sing-box -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/iptables -I OUTPUT 1 -o sing-box -j ACCEPT
      ${pkgs.iptables}/bin/ip6tables -C OUTPUT -o tun+ -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/ip6tables -I OUTPUT 1 -o tun+ -j ACCEPT 2>/dev/null || true
      ${pkgs.iptables}/bin/ip6tables -C OUTPUT -o clash+ -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/ip6tables -I OUTPUT 1 -o clash+ -j ACCEPT 2>/dev/null || true
      ${pkgs.iptables}/bin/ip6tables -C OUTPUT -o sing-box -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/ip6tables -I OUTPUT 1 -o sing-box -j ACCEPT 2>/dev/null || true

      # Исключение приватных IP-адресов серверов/прокси из SOPS/age (secrets.yaml)
      if [ -f "${config.sops.secrets.zapret_exclude_ips.path}" ]; then
        while IFS= read -r ip || [ -n "$ip" ]; do
          ip="$(echo "$ip" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
          [ -z "$ip" ] && continue
          if echo "$ip" | grep -q ':'; then
            ${pkgs.ipset}/bin/ipset add nozapret6 "$ip" 2>/dev/null || true
            ${pkgs.iptables}/bin/ip6tables -C OUTPUT -d "$ip" -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/ip6tables -I OUTPUT 1 -d "$ip" -j ACCEPT 2>/dev/null || true
          else
            ${pkgs.ipset}/bin/ipset add nozapret "$ip" 2>/dev/null || true
            ${pkgs.iptables}/bin/iptables -C OUTPUT -d "$ip" -j ACCEPT 2>/dev/null || ${pkgs.iptables}/bin/iptables -I OUTPUT 1 -d "$ip" -j ACCEPT 2>/dev/null || true
          fi
        done < "${config.sops.secrets.zapret_exclude_ips.path}"
      fi
    '';
  };
}
