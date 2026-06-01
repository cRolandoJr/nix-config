{ config, pkgs, lib, ... }:

let
  # Wallpaper del greeter SDDM: gradient azul cósmico con el snowflake
  # oficial NixOS centrado como watermark gigante (600px alto, opacity 25%).
  # El form y el clock del tema astronaut quedan encima del logo, que actúa
  # como branding de fondo sin competir visualmente.
  sddmWallpaper = pkgs.runCommand "sddm-wallpaper-nixos.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    logo="${pkgs.nixos-icons}/share/icons/hicolor/1024x1024/apps/nix-snowflake.png"

    magick -size 1920x1080 gradient:'#0a0e27-#1a1f4e' base.png
    magick "$logo" -resize x600 -alpha set \
      -channel A -evaluate multiply 0.25 +channel logo.png
    magick base.png logo.png -gravity center -composite $out
  '';

  # Package SDDM theme con overrides. Lo definimos una vez y lo referenciamos
  # tanto en services.displayManager.sddm.extraPackages COMO en
  # environment.systemPackages: el módulo SDDM en NixOS no propaga
  # extraPackages al share/sddm/themes/ del wrapped binary, así que sin la
  # entry en systemPackages el theme queda "instalado pero no visible" y
  # SDDM cae al theme default (Maui).
  sddmAstronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      Background = "${sddmWallpaper}";
      # HeaderText vacío: el texto "NixOS" ya está integrado en el wallpaper
      # encima del snowflake; setearlo aquí duplicaría el texto superpuesto
      # al clock.
      HeaderText = "";
      AccentColor = "#5277C3";
      DimBackground = "0.0";
      FullBlur = "";
      PartialBlur = "false";
      CropBackground = "true";
    };
  };
in
{
  # Hyprland (Wayland compositor) gestionado por UWSM.
  # Nota: el paquete provee dos sesiones .desktop ("Hyprland" sin UWSM y
  # "Hyprland (uwsm-managed)"). Las dejamos ambas intactas — modificar el
  # .desktop o el Exec para unificarlas rompe la inicialización de UWSM
  # ("PID exited with RC 0" pero el compositor nunca arranca). regreet
  # recuerda la última sesión seleccionada, así que basta con elegir
  # "Hyprland (uwsm-managed)" en el primer login.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Display manager: SDDM con backend X11 + tema sddm-astronaut.
  # Razones para X11 (no Wayland) en el greeter:
  #   - El touchpad funciona out-of-the-box (en SDDM-Wayland el compositor
  #     weston-kiosk default no detecta bien libinput en este hardware).
  #   - Los temas SDDM QT6 (sddm-astronaut, sugar-dark, etc.) están diseñados
  #     para X11 y renderean mejor ahí.
  # La sesión Hyprland sigue siendo Wayland — solo el greeter es X11.
  # services.xserver.enable arranca el X server SOLO para SDDM; las sesiones
  # gráficas elegidas en el login siguen siendo las que provee cada paquete
  # (Hyprland-uwsm sigue siendo Wayland).
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "sddm-astronaut-theme";
    extraPackages = [ sddmAstronaut pkgs.kdePackages.qtmultimedia ];
    # Desactivar el virtual keyboard (qtvirtualkeyboard se enciende por
    # default en QT6 y aparece como un teclado táctil enorme cubriendo la
    # pantalla).
    settings.General.InputMethod = "";
  };

  # Keyboard layout para XWayland (apps X11 corriendo bajo Hyprland).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # XDG portals: hyprland (nativo) + gtk (fallback para apps que no
  # implementan los interfaces que ofrece hyprland).
  # config.hyprland fija explícitamente ScreenCast/Screenshot al backend
  # hyprland — sin esto, apps Electron/Chrome enrutan al picker GTK feo.
  xdg.portal = {
    enable = true;
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    };
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

    # Tema SDDM (también en sddm.extraPackages; ambos necesarios — ver let).
    sddmAstronaut
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

  # Daemon de notificación al cambiar layout de teclado.
  # Escucha el socket de eventos de Hyprland. Necesita HYPRLAND_INSTANCE_SIGNATURE
  # y XDG_RUNTIME_DIR, que UWSM importa al systemd-user manager al iniciar
  # la sesión gráfica (por eso wantedBy/after graphical-session.target).
  # partOf hace que se detenga al cerrar sesión.
  #
  # `path` inyecta bash (shebang #!/usr/bin/env bash), socat (lee el socket
  # de eventos) y libnotify (notify-send) al PATH del unit; sin esto el
  # systemd-user manager arranca con un PATH mínimo y el script muere con
  # status 127 ("bash: No such file") en un loop de restarts.
  systemd.user.services.notify-layout = {
    description = "Hyprland keyboard layout change notifier";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = with pkgs; [ bash socat libnotify ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/rolando/.config/hypr/scripts/notify-layout.sh";
      Restart = "on-failure";
      RestartSec = 5;
      # Tope al loop de restarts: 5 intentos en 60s y systemd lo deja.
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
  };

  # KDEConnect: puertos en firewall
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}
