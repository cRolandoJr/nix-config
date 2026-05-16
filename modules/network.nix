{ config, pkgs, lib, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;   # CRÍTICO: RTL8852BE se cuelga con powersave on
    wifi.backend = "iwd";     # backend moderno, más estable que wpa_supplicant
  };

  # Firmware redistribuible (necesario para Realtek WiFi, AMD GPU, etc.)
  hardware.enableRedistributableFirmware = true;

  # Firewall básico
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;   # habilita features modernos (battery indicator, etc.)
      };
    };
  };
  services.blueman.enable = true;

  # DNS rápido y resolución resiliente
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "false";
      FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
