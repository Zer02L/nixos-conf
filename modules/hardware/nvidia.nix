{ config, lib, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
