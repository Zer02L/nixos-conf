{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.vpnTimezone;

  syncScript = pkgs.writeShellScriptBin "sync-vpn-timezone" ''
    set -euo pipefail

    DEFAULT_TZ="${cfg.defaultTimeZone}"
    INTERFACE_PATTERN="${cfg.interfacePattern}"

    # Ищем активные (UP) интерфейсы туннелей
    ACTIVE_VPN=$(${pkgs.iproute2}/bin/ip -br link 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E "$INTERFACE_PATTERN" | ${pkgs.gnugrep}/bin/grep "UP" || true)

    if [ -n "$ACTIVE_VPN" ]; then
      echo "[vpn-timezone] Обнаружен активный VPN-интерфейс:"
      echo "$ACTIVE_VPN"

      # Запрашиваем таймзону с надёжным таймаутом и fallback-сервисом
      DETECTED_TZ=$(${pkgs.curl}/bin/curl -s --connect-timeout 4 --max-time 6 https://ipapi.co/timezone 2>/dev/null || true)

      if [ -z "$DETECTED_TZ" ] || [[ "$DETECTED_TZ" == *"error"* ]]; then
        DETECTED_TZ=$(${pkgs.curl}/bin/curl -s --connect-timeout 4 --max-time 6 "https://ip-api.com/line?fields=timezone" 2>/dev/null || true)
      fi

      if [ -n "$DETECTED_TZ" ]; then
        CURRENT_TZ=$(${pkgs.systemd}/bin/timedatectl show --property=Timezone --value 2>/dev/null || true)
        if [ "$CURRENT_TZ" != "$DETECTED_TZ" ]; then
          echo "[vpn-timezone] Переключение часового пояса: $CURRENT_TZ -> $DETECTED_TZ"
          ${pkgs.systemd}/bin/timedatectl set-timezone "$DETECTED_TZ"
        else
          echo "[vpn-timezone] Часовой пояс уже соответствует VPN: $DETECTED_TZ"
        fi
      else
        echo "[vpn-timezone] Предупреждение: не удалось определить часовой пояс по внешнему IP"
      fi
    else
      CURRENT_TZ=$(${pkgs.systemd}/bin/timedatectl show --property=Timezone --value 2>/dev/null || true)
      if [ "$CURRENT_TZ" != "$DEFAULT_TZ" ]; then
        echo "[vpn-timezone] VPN отключен. Возврат к домашнему часовому поясу: $CURRENT_TZ -> $DEFAULT_TZ"
        ${pkgs.systemd}/bin/timedatectl set-timezone "$DEFAULT_TZ"
      else
        echo "[vpn-timezone] Домашний часовой пояс уже установлен ($DEFAULT_TZ)"
      fi
    fi
  '';
in
{
  options.services.vpnTimezone = {
    enable = mkEnableOption "Автоматическая подстройка системного времени под локацию VPN/Proxy";

    defaultTimeZone = mkOption {
      type = types.str;
      default = "Europe/Moscow";
      description = "Часовой пояс по умолчанию при выключенном VPN.";
    };

    interfacePattern = mkOption {
      type = types.str;
      default = "^(happ|tun|wg|tap|clash|meta|proton|mullvad|warp)";
      description = "Регулярное выражение для поиска интерфейсов VPN/TUN.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ syncScript ];

    # Служба для запуска скрипта синхронизации
    systemd.services.vpn-timezone-sync = {
      description = "Sync system timezone with VPN/proxy location";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${syncScript}/bin/sync-vpn-timezone";
      };
      # Запускаем после поднятия сети при загрузке системы
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # Мгновенная реакция udev на создание/удаление VPN-интерфейсов
    services.udev.extraRules = ''
      ACTION=="add|remove", SUBSYSTEM=="net", KERNEL=="happ*|tun*|wg*|tap*|clash*|meta*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="vpn-timezone-sync.service"
    '';
  };
}
