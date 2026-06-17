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

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
}
