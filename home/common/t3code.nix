# Home-Manager module: T3 Code editor & CLI tools
# Supports switching channels between "stable" and "nightly".
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.custom.t3code;
in
{
  options.custom.t3code = {
    enable = lib.mkEnableOption "T3 Code editor & CLI tools" // { default = true; };

    channel = lib.mkOption {
      type = lib.types.enum [ "stable" "nightly" ];
      default = "nightly";
      description = "Release channel for T3 Code ('stable' or 'nightly').";
    };

    gui = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install T3 Code desktop GUI package.";
    };

    cli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install T3 Code CLI package.";
    };

    guiPackage = lib.mkOption {
      type = lib.types.package;
      default = if cfg.channel == "nightly" then pkgs.t3code-nightly else pkgs.t3code;
      defaultText = lib.literalExpression ''if cfg.channel == "nightly" then pkgs.t3code-nightly else pkgs.t3code'';
      description = "T3 Code GUI package to install.";
    };

    cliPackage = lib.mkOption {
      type = lib.types.package;
      default = if cfg.channel == "nightly" then pkgs.t3-cli-nightly else pkgs.t3-cli;
      defaultText = lib.literalExpression ''if cfg.channel == "nightly" then pkgs.t3-cli-nightly else pkgs.t3-cli'';
      description = "T3 Code CLI package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.concatLists [
      (lib.optional cfg.gui cfg.guiPackage)
      (lib.optional cfg.cli cfg.cliPackage)
    ];
  };
}
