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
    nvfetcher

    # C++
    gcc
    gnumake

    # C# .NET
    dotnet-sdk_11

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
    gotools
    golangci-lint

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

    # Вместо Docker используется Podman (настроен в modules/services/podman.nix с dockerCompat и dockerSocket)
    # docker
    docker-language-server

    turso-cli # вместо sql

  ];
}
