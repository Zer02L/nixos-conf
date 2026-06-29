{ config, lib, pkgs, ... }: {
  services.pipewire = {
    enable = true;
    pulse.enable = true;

    wireplumber.extraConfig."50-fifine-volume" = {
      # Force Fifine USB microphone source volume to 100% at node creation.
      # The monitor.alsa.rules fire when an ALSA source node is registered,
      # before the session item wraps it — so node.volume is read by
      # si-audio-adapter as the initial volume.
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "~alsa_input.usb-3142_Fifine_Microphone-00.*"; }
          ];
          actions."apply-properties" = {
            "node.volume" = 1.0;
          };
        }
      ];
    };
  };
}
