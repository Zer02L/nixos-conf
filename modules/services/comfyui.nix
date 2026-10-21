# ComfyUI systemd service module (через flake comfyui-nix).
# Примечание: сборка PyTorch/CUDA через Nix может инициировать долгую локальную
# компиляцию при отсутствии бинарного кэша.
# В качестве готовой альтернативы без компиляции используется Podman-стек в ~/comfyui
# Подробная документация: docs/COMFYUI.md

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  services.comfyui = {
    enable = true;
    package = inputs.comfyui-nix.packages.${pkgs.system}.cuda; # или просто pkgs.comfyui-cuda, если оверлей добавлен
    # Выберите нужный пакет:
    # package = pkgs.comfyui;          # CPU-версия (по умолчанию)
    # package = pkgs.comfyui-cuda;    # NVIDIA (если overlay добавлен)
    # package = pkgs.comfyui-rocm;    # AMD
    # package = pkgs.comfyui-xpu;     # Intel

    listen = [
      "127.0.0.1"
      "::1"
    ]; # Для доступа из сети поменяйте на "0.0.0.0"
    port = 8188; # Порт (можно изменить)
    dataDir = "/var/lib/comfyui"; # Папка для моделей, выходов и конфигов
    extraArgs = [ ]; # Дополнительные аргументы (опционально)
  };
}
