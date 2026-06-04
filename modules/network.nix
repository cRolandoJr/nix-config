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
  };

  # Evitar que un soft-block transitorio de rfkill se restaure al bootear
  # y deje el WiFi muerto. Sin esto, systemd-rfkill persiste el estado en
  # /var/lib/systemd/rfkill/ y lo replay-ea en el siguiente arranque.
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

  # Workaround nixpkgs unstable (26.05, build 2026-05-15): el drop-in generado
  # por NixOS agrega un segundo ExecStart= sobre el unit upstream que tiene
  # Type=dbus + ExecStart=. Systemd lo rechaza ("more than one ExecStart").
  # Reseteamos con "" y volvemos a setear uno solo.
  systemd.user.services.blueman-applet.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.blueman}/bin/blueman-applet"
  ];

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
