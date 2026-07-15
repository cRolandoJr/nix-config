{
  config,
  pkgs,
  lib,
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

  # scx_lavd: scheduler latency-aware (requiere kernel ≥ 6.12).
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };
}
