{ config, pkgs, lib, ... }:

{
  # Driver amdgpu para iGPU (Radeon 680M) y dGPU (RX 6500M)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # OpenGL / Vulkan
  hardware.graphics = {
    enable = true;
    enable32Bit = true;     # Steam, juegos de 32 bits
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # OpenCL para AMD
      libva-vdpau-driver            # decoding de video
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      libva-vdpau-driver
    ];
  };

  # Variables de entorno para Wayland + AMD
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  # Herramientas útiles para AMD
  environment.systemPackages = with pkgs; [
    radeontop          # monitor de uso GPU
    vulkan-tools       # vulkaninfo, vkcube
    mesa-demos            # info OpenGL
    libva-utils        # vainfo
  ];

  # Power management para laptop (tlp es bueno pero choca con power-profiles-daemon de KDE)
  # KDE 6 usa power-profiles-daemon por defecto, lo dejamos así.
  services.power-profiles-daemon.enable = true;
}
