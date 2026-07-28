{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Wallpaper SDDM generado: gradient azul + snowflake NixOS centrado (opacity 25%).
  sddmWallpaper =
    pkgs.runCommand "sddm-wallpaper-nixos.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        logo="${pkgs.nixos-icons}/share/icons/hicolor/1024x1024/apps/nix-snowflake.png"

        magick -size 1920x1080 gradient:'#0a0e27-#1a1f4e' base.png
        magick "$logo" -resize x600 -alpha set \
          -channel A -evaluate multiply 0.25 +channel logo.png
        magick base.png logo.png -gravity center -composite $out
      '';

  # Definido una vez, referenciado en extraPackages Y systemPackages.
  # Sin la entry en systemPackages el theme no queda visible para SDDM (cae a Maui).
  sddmAstronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      Background = "${sddmWallpaper}";
      HeaderText = ""; # el wallpaper ya incluye el logo; texto aquí lo duplicaría
      AccentColor = "#5277C3";
      DimBackground = "0.0";
      FullBlur = "";
      PartialBlur = "false";
      CropBackground = "true";
    };
  };
in
{
  # No modificar los .desktop generados: unificar "Hyprland" y "Hyprland (uwsm-managed)"
  # rompe la inicialización de UWSM (sale RC 0 pero el compositor nunca arranca).
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  services.xserver.enable = true; # solo para SDDM greeter; sesión Hyprland es Wayland

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "sddm-astronaut-theme";
    extraPackages = [
      sddmAstronaut
      pkgs.kdePackages.qtmultimedia
    ];
    settings.General.InputMethod = ""; # deshabilita qtvirtualkeyboard (cubre la pantalla por default)
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Sin config.hyprland explícito, Electron/Chrome usan el picker GTK.
  xdg.portal = {
    enable = true;
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # xdph es Type=dbus sin WantedBy: si nadie activa su bus name, el picker de
  # captura nunca aparece. Forzar WantedBy lo levanta junto con la sesión.
  systemd.user.services.xdg-desktop-portal-hyprland.wantedBy = [ "graphical-session.target" ];

  # Sin Flatpak ni AppImages el document portal no tiene consumidor, y sin
  # fusermount3 falla al montar /run/user/1000/doc (unit en failed permanente).
  # enable=false = mask (symlink a /dev/null). Revertir si algún día una app
  # sandboxeada no puede abrir/guardar archivos.
  systemd.user.units."xdg-document-portal.service".enable = false;

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    # El agente polkit lo lanza el XDG-autostart del propio paquete (via UWSM);
    # no declarar una unit manual: el segundo registro falla ("agent already exists").
    polkit_gnome
    qalculate-gtk
    gparted
    baobab
    zathura
    kdePackages.kdeconnect-kde

    sddmAstronaut # también en sddm.extraPackages (ver let)
  ];

  systemd.user.services.notify-layout = {
    description = "Hyprland keyboard layout change notifier";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = with pkgs; [
      bash
      nmap
      libnotify
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "%h/.config/hypr/scripts/notify-layout.sh"; # %h = $HOME (specifier systemd)
      Restart = "on-failure";
      RestartSec = 5;
    };
    # El rate-limit va en [Unit], no en [Service]: ahí systemd lo ignora en
    # silencio y queda el default de 10s, que con RestartSec=5 nunca se alcanza.
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
  };

  networking.firewall = {
    # KDEConnect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
}
