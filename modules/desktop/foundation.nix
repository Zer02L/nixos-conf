{ lib, ... }: {
  # Общий фундамент для всех DE/WM (XWayland, порталы, шрифты)
  services.xserver.enable = true;
}
