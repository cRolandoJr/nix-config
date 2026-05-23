{ config, pkgs, lib, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Cargar amdgpu en initrd (mejor estabilidad)
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      libva-vdpau-driver
    ];
  };

  # LACT — control de GPU AMD (overclock, power limit, fan curves)
  services.lact.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV";       # forzar RADV, no amdvlk
    RADV_PERFTEST = "gpl";         # gpl=graphics pipeline library; SAM/ReBAR ya manejado por RADV en kernel 7+
  };

  environment.systemPackages = with pkgs; [
    radeontop
    vulkan-tools
    mesa-demos
    libva-utils
    lact                           # GUI para controlar la GPU
  ];

  services.power-profiles-daemon.enable = true;
}
