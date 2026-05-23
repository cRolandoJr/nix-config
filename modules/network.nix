{ config, pkgs, lib, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    wifi.backend = "iwd";
  };

  hardware.enableRedistributableFirmware = true;

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
        # "dual" habilita BR/EDR (audífonos A2DP/aptX) + BLE (controllers, mouse).
        controllerMode = "dual";
      };
    };
  };
  services.blueman.enable = true;

  systemd.services.bluetooth.serviceConfig = {
    ExecStart = lib.mkForce [
      ""
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --noplugin=sap"
    ];
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "false";
      FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
