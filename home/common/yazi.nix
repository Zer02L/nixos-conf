{ config, pkgs, ... }: {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };
}
