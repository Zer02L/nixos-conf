{ inputs, ... }: {
  imports = [ ../profiles/desktop.nix ];

  home.username = "zerg";
  home.homeDirectory = "/home/zerg";

}
