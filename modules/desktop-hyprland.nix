{ config, pkgs, lib, ... }:

{
  # Hyprland (Wayland compositor)
  programs.hyprland = {
    enable = true;
    withUWSM = false;
  };

  # XDG portals: el portal-kde lo aporta desktop-kde.nix (NixOS merge de listas).
  # Si en el futuro sacás KDE, agregá xdg-desktop-portal-gtk acá como fallback.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
    ];
  };

  # Polkit (autorizaciones: mounts, network, etc.)
  security.polkit.enable = true;

  # Polkit agent (para que salgan prompts en sesiones Wayland/Hyprland)
  # Usamos polkit_gnome y lo autostarteamos.
  environment.systemPackages = with pkgs; [
    polkit_gnome
  ];

  # Autostart del polkit agent (systemd --user)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  # (Opcional) Si querés asegurar que apps X11 funcionen bien
#  services.xserver.enable = true;

  # (Opcional) xwaylandvideobridge, si llega a existir en tu nixpkgs
  # environment.systemPackages = with pkgs; [
  #   xwaylandvideobridge
  # ];
}
