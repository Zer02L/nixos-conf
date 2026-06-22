{ config, pkgs, ... }: {
  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.omniroute = {
      image = "diegosouzapw/omniroute:latest";
      ports = [ "20128:20128" ];
      volumes = [
        "/var/lib/omniroute:/root/.omniroute"
      ];
      autoStart = true;
    };
  };
}
