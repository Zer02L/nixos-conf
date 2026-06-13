{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "z";
      user.email = "z@example.org";
      include.path = "~/.config/git/config-dotfiles";
      core.askPass = "";
    };
  };
}
