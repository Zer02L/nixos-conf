{ config, lib, pkgs, ... }: {
  programs.chromium = {
    enable = true;
    extraOpts = {
      "BraveRewardsDisabled" = true;
      "BraveAIChatEnabled" = false;
      "PasswordManagerEnabled" = false;

      "ExtensionInstallForcelist" = [
        "mnjggcdmjocbbbhaepdhghnkhapgblgc;https://google.com" # SponsorBlock
        "jinjgcalioegnnleocomhbbikfjgocmm;https://google.com" # Violentmonkey
        "ajofdfbaidgndichclgocbhgbeoolbif;https://google.com" # ScriptCat
      ];

      "CommandLineArgs" = [
        "--password-store=basic"
        "--disable-features=VaapiVideoDecoder"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    (pkgs.brave.override {
      commandLineArgs = "--password-store=basic --disable-features=UseOzonePlatform --ozone-platform=wayland";
    })
  ];
}
