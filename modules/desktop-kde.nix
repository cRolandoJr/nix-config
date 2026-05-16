{ config, pkgs, lib, ... }:

{
  # X11 base (necesario aunque uses Wayland — algunos componentes)
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # SDDM como display manager con Wayland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Excluir apps de KDE que no quiero (podés ajustar la lista)
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa            # reproductor música
    kate             # ya tenés nano/nvim
    khelpcenter
    plasma-browser-integration
  ];

  # Apps KDE útiles que sí quiero
  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    kdeconnect-kde
    partitionmanager
    filelight        # visualizador de uso de disco
    spectacle        # screenshots
    okular           # PDF viewer
    ark              # extractor de archivos
  ];

  # Fuentes
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      jetbrains-mono
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  # Portales (necesarios para Wayland + Flatpak + screen sharing)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs.kdePackages; [
      xdg-desktop-portal-kde
    ];
  };

  # KDEConnect (sync con celular)
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}
