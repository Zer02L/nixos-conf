{ config, lib, pkgs, ... }: {
  users.users.zerg = {
    isNormalUser = true;
    linger = true;
    extraGroups = [ "wheel" "networkmanager" "video" "podman" ];
    shell = pkgs.fish;
    packages = with pkgs; [ tree ];
  };
}
