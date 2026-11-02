{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.comfyui-podman;
  user = "zerg";
  homeDir = "/home/${user}";
  dataDir = "${homeDir}/comfyui/storage";
in
{
  options.services.comfyui-podman = {
    enable = lib.mkEnableOption "declarative rootless ComfyUI service via Podman";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start ComfyUI service automatically on user login/boot (requires systemd lingering)";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "Port to expose ComfyUI web UI";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/yanwk/comfyui-boot:cu126-slim";
      description = "Podman/OCI container image for ComfyUI";
    };

    storageDir = lib.mkOption {
      type = lib.types.str;
      default = dataDir;
      description = "Path to storage directory containing models, outputs, custom nodes and caches";
    };
  };

  config = lib.mkIf cfg.enable {
    # Включаем podman и поддержку nvidia container toolkit
    virtualisation.podman.enable = true;
    virtualisation.containers.enable = true;
    hardware.nvidia-container-toolkit.enable = true;

    # Декларативный rootless systemd user-сервис для пользователя zerg.
    # Преимущества rootless:
    # 1. Запуск и управление без sudo (`systemctl --user start comfyui` или `comfy start`).
    # 2. Все модели, ноды и сгенерированные файлы принадлежат пользователю zerg:users.
    # 3. Используется уже загруженный локальный образ (cu126-slim).
    systemd.user.services.comfyui = {
      description = "ComfyUI AI Image Generation Service (Podman)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";
        ExecStartPre = [
          # Гарантируем наличие необходимых каталогов в storage
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.storageDir}/models ${cfg.storageDir}/custom_nodes ${cfg.storageDir}/input ${cfg.storageDir}/output ${cfg.storageDir}/user ${cfg.storageDir}/dot-cache ${cfg.storageDir}/dot-local"
          # Генерация чистого манифеста CDI без несуществующих системных путей
          "${pkgs.writeShellScript "comfyui-cdi-fix" ''
            if [ -f /var/run/cdi/nvidia-container-toolkit.json ]; then
              ${pkgs.python3}/bin/python3 -c "
import json, os
try:
    with open('/var/run/cdi/nvidia-container-toolkit.json') as f:
        d = json.load(f)
    d['containerEdits']['mounts'] = [m for m in d.get('containerEdits', {}).get('mounts', []) if os.path.exists(m['hostPath'])]
    os.makedirs('${homeDir}/.config/cdi', exist_ok=True)
    with open('${homeDir}/.config/cdi/nvidia.json', 'w') as f:
        json.dump(d, f, indent=2)
except Exception:
    pass
"
            fi
          ''}"
          # Настройка ComfyUI-Manager (разрешаем установку нод для доверенного локального хоста)
          "${pkgs.writeShellScript "comfyui-manager-config" ''
            MGR_DIR="${cfg.storageDir}/user/__manager"
            ${pkgs.coreutils}/bin/mkdir -p "$MGR_DIR"
            if [ ! -f "$MGR_DIR/config.ini" ]; then
              cat << 'EOF' > "$MGR_DIR/config.ini"
[default]
use_uv = False
security_level = weak
allow_flagged_nodepack_install = True
downgrade_blacklist = torch, torchvision, torchaudio
EOF
            else
              if ! grep -q "allow_flagged_nodepack_install" "$MGR_DIR/config.ini"; then
                echo "allow_flagged_nodepack_install = True" >> "$MGR_DIR/config.ini"
              fi
            fi
          ''}"
          # Удаляем зависший контейнер с тем же именем, если он остался от предыдущего сеанса
          "-${pkgs.podman}/bin/podman rm -f comfyui"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.podman}/bin/podman run"
          "--name comfyui"
          "--replace"
          "--rm"
          "--stop-signal SIGINT"
          "-p 127.0.0.1:${toString cfg.port}:8188"
          "--device nvidia.com/gpu=all"
          "-e CLI_ARGS='--listen 0.0.0.0 --port 8188 --enable-manager'"
          "-v ${cfg.storageDir}/models:/root/ComfyUI/models:Z"
          "-v ${cfg.storageDir}/custom_nodes:/root/ComfyUI/custom_nodes:Z"
          "-v ${cfg.storageDir}/input:/root/ComfyUI/input:Z"
          "-v ${cfg.storageDir}/output:/root/ComfyUI/output:Z"
          "-v ${cfg.storageDir}/user:/root/ComfyUI/user:Z"
          "-v ${cfg.storageDir}/dot-cache:/root/.cache:Z"
          "-v ${cfg.storageDir}/dot-local:/root/.local:Z"
          cfg.image
        ];
        ExecStop = "${pkgs.podman}/bin/podman stop -t 10 comfyui";
      };

      wantedBy = lib.optionals cfg.autoStart [ "default.target" ];
    };
  };
}
