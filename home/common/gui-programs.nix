{
  config,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
  ...
}:
{
  home.packages = (
    with pkgs;
    [

      # media
      mpv
      obs-studio
      obs-studio-plugins.obs-vkcapture # захват игр (Vulkan/OpenGL) на Wayland

      # network
      v2rayn
      telegram-desktop

      # productivity
      handy
      super-productivity
      obsidian

      # browsers (nvfetcher)
      brave
      brave-origin

      # editors
      zed-editor
      vscode
      #
      opencode-desktop
      opencode

      # t3code (official release pingdotgg/t3code)
      t3code

      # artcraft-launcher (storytold/craft-launcher via nvfetcher)
      artcraft-launcher

      godot
      blender
      creabim

      protonup-rs

      qbittorrent

      vesktop

      amnezia-vpn

      r2modman
      # amethyst-mod-manager (ChrisDKN/Amethyst-Mod-Manager via nvfetcher)
      amethyst-mod-manager
      # bottles
      lutris

      # KDE
      # kdePackages.karousel
    ]
    ++ (with pkgs-stable; [
      # стабильные версии
      activitywatch
      audacity
    ])
  );
}
