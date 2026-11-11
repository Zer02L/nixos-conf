{ lib
, stdenv
, autoPatchelfHook
, makeBinaryWrapper
, ripgrep
, fd
, callPackage
, sources ? callPackage ../_sources/generated.nix {}
}:

let
  src-info = sources.pi-coding-agent;
in
stdenv.mkDerivation {
  inherit (src-info) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  # Bun single-file executables embed the JS bundle at the end of the ELF binary.
  # Running strip would destroy this payload and cause the binary to fall back to plain Bun.
  dontStrip = true;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m 755 -D pi/pi $out/bin/pi
    ln -s $out/bin/pi $out/bin/pi-coding-agent
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [ ripgrep fd ]} \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0
  '';

  meta = with lib; {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pi";
  };
}
