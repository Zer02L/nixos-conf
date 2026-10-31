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

      # inputs.comfyui-nix.packages.x86_64-linux.cuda

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

      brave
      brave-origin

      # editors
      zed-editor
      vscode
      #
      opencode-desktop
      opencode

      # t3code (официальный релиз pingdotgg/t3code)
      (pkgs.callPackage ./pkgs/t3code.nix { })

      godot
      blender

      protonup-rs

      qbittorrent

      vesktop
      onlyoffice-desktopeditors

      amnezia-vpn

      r2modman
      # amethyst-mod-manager (ChrisDKN/Amethyst-Mod-Manager via nvfetcher)
      (pkgs.callPackage ./pkgs/amethyst-mod-manager.nix { })
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
