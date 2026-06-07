{
  config,
  pkgs,
  lib,
  ...
}:

{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
    editor = false; # no permitir editar cmdline al boot
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.supportedFilesystems = [
    "btrfs"
    "vfat"
  ];

  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  # Mensajes siguen en dmesg/journalctl; solo se ocultan visualmente (panic sigue mostrándose).
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.initrd.systemd.enable = true; # necesario para el prompt de LUKS
  boot.plymouth.enable = true;
}
