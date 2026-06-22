{ config, pkgs, ... }: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/mnt/db/postgresql";
  };
}
