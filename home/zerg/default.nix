{ inputs, ... }: {
  imports = [ inputs.self.homeManagerModules.default ];

  home.username = "zerg";
  home.homeDirectory = "/home/zerg";
}
