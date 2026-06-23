{ ... }: {
  imports = [
    ./system.nix
    ./nix.nix
    ./fonts.nix
    ./hardware/nvidia.nix
    ./services/pipewire.nix
    ./services/display-manager.nix
    ./services/zram.nix
    ./services/zapret.nix
    ./programs/brave.nix
    ./programs/steam.nix
    ./services/power.nix
    ./services/postgresql.nix
    ./services/omniroute.nix
    ./programs/admin-tools.nix
    ./users/zerg.nix
    ./networking
  ];
}
