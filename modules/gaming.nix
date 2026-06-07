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

  # Workaround nixpkgs unstable (post-2026-06): programs.steam fuerza setuid en bwrap,
  # pero bubblewrap 0.11+ se compila sin -Dpriv_mode=setuid → aborta al ejecutarse.
  # Solo `setuid = false` no alcanza: el módulo exige `source` explícito.
  # Sobreescribimos el wrapper completo con mkForce.
  security.wrappers.bwrap = lib.mkForce {
    source = "${pkgs.bubblewrap}/bin/bwrap";
    owner = "root";
    group = "root";
    setuid = false;
  };

  # capSysNice: CAP_SYS_NICE para prioridad CPU/GPU; necesario para nested Wayland.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Vulkan 32-bit: en gpu-amd.nix via extraPackages32.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt # gestor de versiones Proton-GE
    wineWow64Packages.stable
    winetricks
    # gamescope ya viene via programs.gamescope.enable
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
