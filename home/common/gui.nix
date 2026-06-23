{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # media
    mpv
    obs-studio
    obs-studio-plugins.obs-vkcapture # захват игр (Vulkan/OpenGL) на Wayland

    # network
    v2rayn
    vesktop
    mullvad-browser
    telegram-desktop

    # productivity
    handy
    super-productivity
    activitywatch
    obsidian

    # editors
    zed-editor-fhs
    vscode-fhs

    blender
    onlyoffice-desktopeditors

    # KDE
    kdePackages.karousel
  ];
}
