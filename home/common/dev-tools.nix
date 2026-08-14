{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Lua
    lua-language-server
    stylua

    # Nix
    nil
    nixd
    nixfmt

    # C++
    gcc

    # Python
    python3
    uv
    ruff
    pyright

    # Rust
    rust-analyzer
    cargo-tauri

    # Go
    go
    gopls

    # JavaScript / TypeScript runtimes & package managers
    nodejs_24
    pnpm
    bun

    typescript-language-server
    vue-language-server
    tailwindcss-language-server

    prettier
    oxlint
    oxfmt

    # Прочее
    yaml-language-server

    # Editors
    neovim

    git
    lazygit

    jujutsu
    lazyjj

    # Code browsing
    bat
    ripgrep
    ripgrep-all

    # Ai Dev tooling
    openspec
    antigravity-cli
    antigravity-ide
    pi-coding-agent
    codex
    codebuff

    # Dev environments
    devenv

    docker
    docker-language-server

    turso-cli # вместо sql
  ];
}
