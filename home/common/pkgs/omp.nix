{ lib
, stdenv
, autoPatchelfHook
, callPackage
, sources ? callPackage ../../../_sources/generated.nix {}
}:

let
  omp-src = sources.omp;
in
stdenv.mkDerivation {
  inherit (omp-src) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dontUnpack = true;
  # Bun single-file executables embed the JS bundle at the end of the ELF binary.
  # Running strip would destroy this payload and cause the binary to fall back to plain Bun.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -m 755 -D $src $out/bin/omp
    runHook postInstall
  '';

  meta = with lib; {
    description = "Oh My Pi (omp) - AI coding agent";
    homepage = "https://omp.sh";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "omp";
  };
}
