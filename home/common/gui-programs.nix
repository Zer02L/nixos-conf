{ config
, lib
, pkgs
, pkgs-stable
, inputs
, ...
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
      # opencode-desktop
      # opencode

      # orca ai / orca-ide (stablyai/orca via nvfetcher)
      orca-ai

      # skills-manager (xingkongliang/skills-manager via nvfetcher)
      skills-manager

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
      # antigravity-manager (lbjlaq/Antigravity-Manager via nvfetcher)
      antigravity-manager
      # kiri container runtime (libracoder/kiri via nvfetcher)
      kiri
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
