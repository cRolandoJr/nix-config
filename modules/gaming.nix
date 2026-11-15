{
  config,
  pkgs,
  lib,
  username,
  ...
}:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  hardware.uinput.enable = true;
  users.users.${username}.extraGroups = [ "uinput" ];

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt # gestor de versiones Proton-GE
    wineWow64Packages.stable
    winetricks
  ];

  hardware.xpadneo.enable = true;

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Star Citizen, algunos juegos modernos
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
