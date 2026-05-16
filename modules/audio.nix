{ config, pkgs, lib, ... }:

{
  # Pipewire reemplaza pulseaudio y jack
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.enable = true;
  };

  # Deshabilitar pulseaudio (lo reemplaza pipewire)
  services.pulseaudio.enable = false;

  # Paquetes útiles de audio
  environment.systemPackages = with pkgs; [
    pavucontrol           # control gráfico de volumen
    playerctl             # control multimedia desde CLI
    pamixer               # mixer CLI
  ];
}
