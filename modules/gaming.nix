{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;       # sesión gamescope para juegos
  };

  # Soporte Vulkan 32-bit ya está en gpu-amd.nix con extraPackages32

  # GameMode: optimiza CPU governor mientras jugás
  programs.gamemode.enable = true;

  # MangoHud: overlay de FPS/temps
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt          # gestor de versiones Proton-GE
    wineWow64Packages.stable
    winetricks
  ];

  # Controles (Xbox, PlayStation, etc.)
  hardware.xpadneo.enable = true;        # mejor driver Xbox

  # Aumentar límite de file watchers (algunos juegos lo piden)
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;     # Star Citizen, algunos juegos modernos
  };
}
