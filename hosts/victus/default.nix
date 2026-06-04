{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/boot.nix
    ../../modules/network.nix
    ../../modules/audio.nix
    ../../modules/fonts.nix
    ../../modules/desktop-hyprland.nix
    ../../modules/gpu-amd.nix
    ../../modules/virtualisation.nix
    ../../modules/gaming.nix
    ../../modules/btrbk.nix
    ../../modules/k3s.nix
  ];

  networking.hostName = "victus";

  # Versión de stateVersion: NO la toques nunca después de instalar.
  system.stateVersion = "25.11";
}
