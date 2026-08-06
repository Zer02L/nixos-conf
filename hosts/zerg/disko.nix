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
                  # ext4 — одна ФС на весь LUKS-контейнер, без subvolumes.
                  # /home, /nix, /mnt/* — обычные каталоги на корневой ФС.
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
