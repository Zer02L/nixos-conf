{ pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;
    # Эмуляция Docker: предоставляет команду `docker` и сокет /var/run/docker.sock
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.containers.enable = true;

  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
