{ lib, ... }:

# Specialisation "battery": hereda TODA la config y solo apaga los daemons
# always-on que power-profiles-daemon no puede controlar (ppd ya maneja
# governor/EPP en runtime). Fase 1: k3s + scx, el grueso del consumo idle;
# ananicy/gamemode se suman solo si la medición con powertop lo justifica.
#
# Uso (nixos-rebuild está en sudo NOPASSWD; switch-to-configuration directo no):
#   entrar:  sudo nixos-rebuild switch --flake ~/projects/nix-config#victus --specialisation battery
#   volver:  rebuild normal (sin --specialisation)
#   al boot: entrada propia en systemd-boot (tag "battery")

{
  specialisation.battery.configuration = {
    system.nixos.tags = [ "battery" ];

    services.k3s.enable = lib.mkForce false;
    services.scx.enable = lib.mkForce false;
  };
}
