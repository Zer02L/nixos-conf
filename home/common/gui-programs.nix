{
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
{
  home.packages =
    (with pkgs; [
      # media
      mpv
      obs-studio
      obs-studio-plugins.obs-vkcapture # захват игр (Vulkan/OpenGL) на Wayland

      # network
      v2rayn
      mullvad-browser
      telegram-desktop

      # productivity
      handy
      super-productivity
      obsidian

      # editors
      zed-editor
      vscode

      godot
      blender

      qbittorrent

      quantframe

      # KDE
      kdePackages.karousel
    ])
    ++ (with pkgs-stable; [
      # стабильные версии
      vesktop
      activitywatch
      onlyoffice-desktopeditors
    ]);
}
