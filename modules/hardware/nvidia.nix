{
  config,
  lib,
  pkgs,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ]; # декодинг (NVDEC) для браузеров
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # VA-API для аппаратного ДЕКОДИРОВАНИЯ видео в браузерах
  # ВАЖНО: NVENC (кодирование) через этот драйвер недоступен.
  # Для аппаратного кодирования стримов используйте OBS Studio с нативным NVENC.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia"; # VA-API → NVDEC (только декодинг)
    NIXOS_OZONE_WL = "1"; # Electron/Chromium → Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # GLX через Nvidia (Qt fix)
  };
}
