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

    # Las salidas marcan el compás del grafo. Por defecto los micros tienen priority.driver 2000 y
    # el parlante 1000: como el echo-cancel de Astro abre el micro apenas suena algo, el micro pasaba
    # a ser driver (quantum 256) y el parlante lo seguía con otro reloj → xruns y distorsión que
    # crece con el rato (medido en CS2 el 29-sep: 900/912 s con el micro de driver, ERR en ráfagas).
    wireplumber.extraConfig."52-output-drives-graph" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_output.*"; } ];
          actions.update-props."priority.driver" = 2500;
        }
      ];
    };

    # Front-end de audio para Astro (asistente de voz): fuente de micro PROCESADA con el módulo
    # echo-cancel de PipeWire (WebRTC) — AEC (cancela lo que suena, ej. la voz de Astro) + supresión
    # de ruido + AGC + pasa-altos. Astro captura de "astro_echo_cancel_source" (PULSE_SOURCE en su
    # run.sh). El nivel se da subiendo el volumen del micro real (wpctl ~2.5); el NS limpia para
    # whisper/wake. El atributo Nix se serializa a la config JSON de PipeWire (claves con punto → comillas).
    extraConfig.pipewire."99-astro-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "monitor.mode" = true;
            "aec.args" = {
              "webrtc.gain_control" = true;
              "webrtc.noise_suppression" = true;
              "webrtc.high_pass_filter" = true;
              "webrtc.voice_detection" = false;
            };
            "source.props" = {
              "node.name" = "astro_echo_cancel_source";
              "node.description" = "Astro Mic (AEC+NS+AGC)";
            };
            "sink.props" = {
              "node.name" = "astro_echo_cancel_sink";
              "node.description" = "Astro Echo-Cancel Sink";
            };
          };
        }
      ];
    };
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pamixer
  ];
}
