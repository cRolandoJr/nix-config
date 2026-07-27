{ pkgs, ... }:
{
  # Astro como servicio de usuario: siempre-on (hands-free) → le hablás por wake-word ("alexa"/
  # "Astro") sin terminal ni atajo. Hereda el entorno gráfico (WAYLAND_DISPLAY, XDG_RUNTIME_DIR,
  # PipeWire) de graphical-session vía UWSM, igual que notify-layout. El modo (wake) y toda la
  # config viven en run.sh.
  systemd.user.services.astro = {
    description = "Astro — asistente de voz hands-free (wake-word)";
    wantedBy = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "pipewire.service"
    ];
    partOf = [ "graphical-session.target" ];
    # run.sh usa nix (nix shell/build) + bash + coreutils; pw-play viene de pipewire; eww dibuja la
    # cara (el servicio tiene PATH propio; sin esto no encuentra eww y la cara no aparece).
    path = with pkgs; [
      bash
      nix
      coreutils
      pipewire
      eww
    ];
    serviceConfig = {
      ExecStart = "%h/projects/astro/run.sh"; # sourcea secrets.env (la key NO va al store)
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
