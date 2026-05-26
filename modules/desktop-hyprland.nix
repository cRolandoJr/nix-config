{ config, pkgs, lib, ... }:

{
  # Hyprland (Wayland compositor)
  programs.hyprland = {
    enable = true;
    withUWSM = false;
  };

  # Display manager: SDDM con soporte Wayland. No depende de Plasma.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Keyboard layout para XWayland (apps X11 corriendo bajo Hyprland).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # XDG portals: hyprland (nativo) + gtk (fallback para apps que no
  # implementan los interfaces que ofrece hyprland).
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Polkit (autorizaciones: mounts, network, etc.)
  security.polkit.enable = true;

  # Polkit agent (para que salgan prompts en sesiones Wayland/Hyprland)
  # Usamos polkit_gnome y lo autostarteamos.
  environment.systemPackages = with pkgs; [
    polkit_gnome

    # === Apps GUI (reemplazos post-KDE) ===
    qalculate-gtk          # ex kcalc
    gparted                # ex kde partitionmanager
    baobab                 # ex filelight (disk usage)
    zathura                # ex okular (PDF, vim-like)
    kdePackages.kdeconnect-kde   # sync con celular (funciona en Hyprland)
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

  # KDEConnect: puertos en firewall
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}
