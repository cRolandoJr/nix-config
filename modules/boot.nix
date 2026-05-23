{ config, pkgs, lib, ... }:

{
  # systemd-boot (UEFI)
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;   # cuántas generaciones mostrar en el menú
    editor = false;            # seguridad: no permitir editar cmdline al boot
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # Kernel: último estable
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Soporte para btrfs
  boot.supportedFilesystems = [ "btrfs" "vfat" ];

  # Parámetros de kernel
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  # initrd: prompt de LUKS visible y funcional
  boot.initrd.systemd.enable = true;

  # Plymouth (splash screen bonito al boot)
  boot.plymouth.enable = true;
}
