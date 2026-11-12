{ lib
, stdenv
, autoPatchelfHook
, callPackage
, sources ? callPackage ../_sources/generated.nix {}
}:

stdenv.mkDerivation {
  inherit (sources.protonup-rs) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  # Tarball contains a single binary at the root, no subdirectory.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m 755 -D protonup-rs $out/bin/protonup-rs
    runHook postInstall
  '';

  meta = with lib; {
    description = "Rust app to install and update GE-Proton for Steam, and Wine-GE for Lutris";
    homepage = "https://github.com/auyer/Protonup-rs";
    changelog = "https://github.com/auyer/Protonup-rs/releases/tag/v${version}";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "protonup-rs";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
