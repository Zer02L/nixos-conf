{
  config,
  lib,
  pkgs,
  inputs,
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
    gnumake

    # Python
    python3
    uv
    ruff
    pyright

    # Rust
    rust-analyzer
    cargo-tauri
    obscura

    # Go
    go
    gopls

    # JavaScript / TypeScript runtimes & package managers
    nodejs_26
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

    coreutils
    uesave

    jujutsu
    lazyjj

    # Code browsing
    bat
    ripgrep
    ripgrep-all

    # Ai Dev tooling
    openspec
    pi-coding-agent
    codex
    codebuff
    # antigravity
    # antigravity-cli

    # Dev environments
    devenv

    docker
    docker-language-server

    turso-cli # вместо sql

  ];
}
