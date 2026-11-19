{ lib
, stdenv
, autoPatchelfHook
, callPackage
, sources ? callPackage ../_sources/generated.nix { }
}:

let
  opencode-src = sources.opencode;
in
stdenv.mkDerivation {
  inherit (opencode-src) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  # Bun single-file executables embed the JS bundle at the end of the ELF binary.
  # Running strip would destroy this payload and cause the binary to fall back to plain Bun.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -m 755 -D opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode CLI - AI coding agent for the terminal";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
}
