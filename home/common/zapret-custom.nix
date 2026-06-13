{ config, pkgs, ... }: {
  home.file.".config/zapret/custom-hosts.txt".text = ''
    youtube.com
    googlevideo.com
    discord.com
    discordapp.com
  '';
}
