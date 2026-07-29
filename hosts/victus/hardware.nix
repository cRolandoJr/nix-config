# Base generada por `nixos-generate-config`, editada a mano después.
#
# Los fileSystems y el LUKS ya NO viven acá: los genera disko desde disk.nix.
# Lo que queda es lo que disko no cubre — módulos de kernel del arranque y el
# microcódigo. Nada de esto tiene UUID, así que es portable a otra máquina tal
# cual; en un equipo distinto solo habría que revisar los módulos de initrd.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
