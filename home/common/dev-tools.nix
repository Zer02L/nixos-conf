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

    # Python
    pyright
    ruff
    uv

    # Rust
    rust-analyzer

    # Go
    gopls

    # JavaScript / TypeScript
    typescript-language-server
    vue-language-server
    tailwindcss-language-server
    prettier
    oxlint
    oxfmt

    # Прочее
    yaml-language-server
  ];
}
