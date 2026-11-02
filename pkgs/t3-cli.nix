{ pkgs ? import <nixpkgs> {}
, sources ? pkgs.callPackage ../_sources/generated.nix {}
}:

let
  t3-src = sources."t3-cli";
  unpacked = pkgs.stdenv.mkDerivation {
    pname = "t3-unpacked";
    inherit (t3-src) version src;
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out
      srcDir=$(find . -maxdepth 1 -type d -name "t3-*-linux-x64" | head -n1)
      if [ -z "$srcDir" ]; then
        srcDir="."
      fi
      cp -r $srcDir/* $out/
      chmod +x $out/t3
    '';
  };
in
pkgs.buildFHSEnv {
  name = "t3";
  targetPkgs = pkgs: with pkgs; [
    stdenv.cc.cc.lib
  ];
  runScript = "${unpacked}/t3";

  meta = with pkgs.lib; {
    description = "T3 Code command line interface and headless server";
    homepage = "https://github.com/pingdotgg/t3code";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3";
  };
}
