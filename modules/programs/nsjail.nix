{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ nsjail ];

  # nsjail использует Linux namespaces и seccomp-bpf для изоляции процессов.
  # На NixOS user namespaces доступны по умолчанию (CONFIG_USER_NS=y).
  # Если нужен unprivileged доступ, убедись что:
  #   security.allowUserNamespaces = true;
  # (по умолчанию включено на NixOS 24.11+)
}
