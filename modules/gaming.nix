{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;       # sesión gamescope como compositor (boot to game)
  };

  # programs.steam fuerza security.wrappers.bwrap.setuid = true, pero
  # nixpkgs compila bubblewrap 0.11+ sin -Dpriv_mode=setuid → al ejecutarse
  # con bit setuid aborta con "setuid use of bubblewrap is not supported
  # in this build". User namespaces están habilitados, así que no lo necesitamos.
  security.wrappers.bwrap.setuid = lib.mkForce false;

  # gamescope como WRAPPER (para usar desde Steam launch options).
  # capSysNice = true le da CAP_SYS_NICE al binary → puede subir prioridad de CPU/GPU
  # y abrir nested correctamente bajo Wayland (Hyprland).
  programs.gamescope = {
    enable = true;
    capSysNice = true;
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
    # gamescope ya viene via programs.gamescope.enable — no duplicar acá
  ];

  # Controles (Xbox, PlayStation, etc.)
  hardware.xpadneo.enable = true;        # mejor driver Xbox

  # Aumentar límite de file watchers (algunos juegos lo piden)
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;     # Star Citizen, algunos juegos modernos
  };

  # Ananicy-cpp: prioridad nice/ionice automática por categoría de proceso.
  # Mantiene a los juegos con CPU/IO priority alta y al background bajo.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # sched-ext: scheduler en userspace. scx_lavd = latency-aware, ideal gaming.
  # Requiere kernel ≥ 6.12 (corremos linuxPackages_latest = 7.x).
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };
}
