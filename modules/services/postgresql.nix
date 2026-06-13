{ config, pkgs, ... }: {
  services.postgresql = {
    enable = true;
    dataDir = "/mnt/db/postgresql";
  };
}
