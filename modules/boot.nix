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
    editor = false;
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

  # TEMPORAL debug freeze s2idle (13/17/21-jul): tras el próximo cuelgue+reboot,
  # `dmesg | grep -i "hash matches"` identifica el device culpable. Retirar al cazarlo.
  # Efecto colateral: pisa el RTC en cada suspend (NTP corrige la hora al resume).
  systemd.tmpfiles.rules = [
    "w /sys/power/pm_trace - - - - 1"
  ];

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
}
