{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # ⚠️ Замените на ваш реальный диск (например, /dev/nvme0n1), если ставите не в виртуалку
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # Настройки для интерактивного ввода пароля руками при установке:
                settings = {
                  allowDiscards = true;
                  # keyFile = "/tmp/secret.key"; # Закомментировано для ручного ввода пароля
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                     
#       "/mnt/games" = {
#         mountpoint = "/mnt/games";
#         mountOptions = [ "noatime" "nodatacow" ];
#       };
# 
#       "/mnt/downloads" = {
#         mountpoint = "/mnt/downloads";
#         mountOptions = [ "noatime" "nodatacow" ];
#       };
# 
#       "/postgresql" = {
#         mountpoint = "/var/lib/postgresql";
#         mountOptions = [ "noatime" "nodatacow" ];
#       };
# 
#       "/mnt/steam" = {
#         mountpoint = "/mnt/steam";
#         mountOptions = [ "noatime" "nodatacow" ];
#       };
#  


                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

