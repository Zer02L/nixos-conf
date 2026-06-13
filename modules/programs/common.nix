{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
    curl
    cryptsetup
    btrfs-progs
    smartmontools

    # LSP-серверы
    lua-language-server
    nil # Nix LSP
    pyright
    ruff # Python LSP + форматтер
    rust-analyzer
    gopls
    typescript-language-server
    yaml-language-server
    vue-language-server # Vue 3 LSP (Volar)
    tailwindcss-language-server # автодополнение Tailwind/UnoCSS-классов

    # Форматтеры
    stylua
    oxlint # JS/TS линтер на Rust
    oxfmt # JS/TS форматтер на Rust
    prettier
    uv # быстрый Python-менеджер (Rust)
    nixfmt
  ];

  programs.appimage.enable = true;
  programs.fish.enable = true;
  programs.firefox.enable = true;
}
