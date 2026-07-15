{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    wifi.backend = "wpa_supplicant";
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  # Sin esto systemd-rfkill persiste soft-blocks en /var/lib/systemd/rfkill/
  # y puede dejar el WiFi muerto al arrancar.
  systemd.services.systemd-rfkill.enable = false;
  systemd.sockets.systemd-rfkill.enable = false;

  hardware.enableRedistributableFirmware = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      8443 # gama23 backend HTTPS
      8081 # gama23 backend HTTP
    ];
    allowedUDPPorts = [ ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      controllerMode = "dual";
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
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
