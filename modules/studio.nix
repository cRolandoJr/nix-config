{ pkgs, ... }:
{
  # Estudio de grabacion se la serie "Nix para DevOps".
  programs.obs-studio.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive # edicion
    ffmpeg # cortrar, convertir, medir duracion
    asciinema # grabar la terminal como texto, no como video
  ];
}
