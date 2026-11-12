{ lib
, stdenv
, autoPatchelfHook
, callPackage
, versionCheckHook
, sources ? callPackage ../_sources/generated.nix {}
}:

stdenv.mkDerivation {
  inherit (sources.obscura) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  # Tarball contains two binaries at the root, no subdirectory.
  sourceRoot = ".";

  # `--version` doesn't spin up a V8 isolate, so it works in the sandbox
  # (the upstream test suite does not — same reason as in nixpkgs).
  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  installPhase = ''
    runHook preInstall
    install -m 755 -D obscura $out/bin/obscura
    install -m 755 -D obscura-worker $out/bin/obscura-worker
    runHook postInstall
  '';

  meta = with lib; {
    description = "Headless browser for AI agents and web scraping";
    homepage = "https://github.com/h4ckf0r0day/obscura";
    license = licenses.asl20;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "obscura";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
