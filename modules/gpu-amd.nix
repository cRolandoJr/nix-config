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
    ];
  };

  services.lact.enable = true; # overclock, power limit, fan curves

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV"; # forzar RADV, no amdvlk
  };

  environment.systemPackages = with pkgs; [
    radeontop
    vulkan-tools
    mesa-demos
    libva-utils
    # lact lo instala services.lact.enable; no duplicar aquí
  ];
}
