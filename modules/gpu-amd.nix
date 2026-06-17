{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  boot.initrd.kernelModules = [ "amdgpu" ]; # carga temprana

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

  services.lact.enable = true; # overclock, power limit, fan curves

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV"; # forzar RADV, no amdvlk
    RADV_PERFTEST = "gpl"; # SAM/ReBAR manejado por RADV en kernel 7+
  };

  environment.systemPackages = with pkgs; [
    radeontop
    vulkan-tools
    mesa-demos
    libva-utils
    lact
  ];

  services.power-profiles-daemon.enable = true;
}
