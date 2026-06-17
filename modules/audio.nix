{
  config,
  pkgs,
  lib,
  ...
}:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.enable = true;

    # autoswitch-to-headset-profile=false: BT se queda en A2DP (no HFP) en llamadas → mic interno.
    # follow-default-target=false: audio no salta solo al conectar BT.
    wireplumber.extraConfig."51-audio-policy" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
        "linking.follow-default-target" = false;
      };
    };
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pamixer
  ];
}
