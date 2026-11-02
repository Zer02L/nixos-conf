# Simple server disk layout with EFI + root ext4 (no encryption needed for typical VPS)
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda"; # /dev/sda, /dev/vda or /dev/nvme0n1 depending on server/hypervisor
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
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
}
