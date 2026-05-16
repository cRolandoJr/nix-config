{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/base.nix
    ../../modules/boot.nix
    ../../modules/network.nix
    ../../modules/audio.nix
    ../../modules/desktop-kde.nix
    ../../modules/gpu-amd.nix
    ../../modules/virtualisation.nix
    ../../modules/gaming.nix
  ];

  networking.hostName = "victus";

  # Versión de stateVersion: NO la toques nunca después de instalar.
  system.stateVersion = "25.11";
}
