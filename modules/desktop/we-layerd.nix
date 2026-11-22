{ config
, inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  useCuda =
    builtins.elem "nvidia" config.services.xserver.videoDrivers
    && (config.nixpkgs.config.allowUnfree or false);

  basePackage =
    if useCuda then
      inputs.we-layerd.packages.${system}.default.override
        {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        }
    else
      inputs.we-layerd.packages.${system}.default;

  # Отключаем глобальный MANGOHUD=1 (из modules/programs/steam.nix) для Vulkan-демона и iced/wgpu GUI
  wrappedPackage = pkgs.symlinkJoin {
    name = "${basePackage.pname}-${basePackage.version}";
    paths = [ basePackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in we-layerd we-gui; do
        rm "$out/bin/$bin"
        makeWrapper "${basePackage}/bin/$bin" "$out/bin/$bin" \
          --set MANGOHUD 0 \
          --set DISABLE_MANGOHUD 1
      done
    '';
    inherit (basePackage) meta;
  };
in
{
  imports = [ inputs.we-layerd.nixosModules.default ];

  services.we-layerd = {
    enable = lib.mkDefault true;
    package = lib.mkDefault wrappedPackage;
  };

  systemd.user.services.we-layerd = lib.mkIf config.services.we-layerd.enable {
    serviceConfig.Environment = [
      "MANGOHUD=0"
      "DISABLE_MANGOHUD=1"
    ];
  };
}
