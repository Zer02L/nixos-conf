{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation rec {
  pname = "jcode";
  version = "0.68.0"; # Укажите нужную версию с GitHub

  # Скачиваем готовый бинарный архив из релизов GitHub вместо исходного кода
  src = pkgs.fetchurl {
    url = "https://github.com{version}/jcode-linux-x86_64.tar.gz";
    # Замените на актуальный хэш (можно узнать через nix-prefetch-url)
    # sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Важно: отключаем фазы сборки, так как компиляция не нужна
  dontBuild = true;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook # Автоматически исправит пути к линкеру в бинарнике
  ];

  # Зависимости, необходимые jcode для работы (например, библиотеки C)
  buildInputs = [
    pkgs.stdenv.cc.cc.lib
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp jcode $out/bin/
    chmod +x $out/bin/jcode
  '';
}
