{ config, lib, pkgs, ... }: {
  users.users.zerg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    packages = with pkgs; [ tree ];
  };
}
