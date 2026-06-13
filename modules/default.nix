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
    ./services/power.nix
    ./programs/common.nix
    ./users/zerg.nix
    ./networking
  ];
}
