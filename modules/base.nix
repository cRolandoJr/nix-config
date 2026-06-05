{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Locale y zona horaria
  time.timeZone = "America/Argentina/Buenos_Aires";

  i18n.defaultLocale = "es_AR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  console.keyMap = "us";

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "rolando"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Garbage collection automático
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Auto-upgrade del store
  nix.optimise.automatic = true;

  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
    # zram es RAM comprimida: querés que el kernel lo use agresivamente.
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0; # zram = random-access, sin read-ahead
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  # THP en "madvise": evita compactación global que produce stutter en juegos.
  # Apps que se benefician (jemalloc, juegos modernos) lo activan via madvise().
  boot.kernelParams = [ "transparent_hugepage=madvise" ];

  # Unfree packages (drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Usuario rolando
  users.users.rolando = {
    isNormalUser = true;
    description = "Rolando";
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "video"
      "audio"
      "libvirtd" # KVM/QEMU
      "kvm"
      "input"
      "bluetooth"
      "podman"
    ];
    shell = pkgs.zsh;
  };

  # Habilitar zsh a nivel sistema (necesario para users.shell = pkgs.zsh)
  programs.zsh.enable = true;
  # sudo: password requerido por default, NOPASSWD quirúrgico solo para
  # comandos de mantenimiento frecuentes (rebuild, snapshots, garbage collect).
  # Reduce blast radius si un script comprometido corriera como rolando:
  # no puede escalar a root para tareas arbitrarias, solo las whitelistadas.
  security.sudo = {
    wheelNeedsPassword = true;
    # Defaults lecture=never: oculta el speech "Confiamos que haya recibido
    # la charla habitual del administrador..." la primera vez que usás sudo
    # en una sesión. Ruido innecesario para single-user laptop.
    extraConfig = ''
      Defaults lecture=never
    '';
    extraRules = [
      {
        users = [ "rolando" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/btrbk";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  # Paquetes base imprescindibles
  environment.systemPackages = with pkgs; [
    # Editores
    vim
    nano

    # Herramientas de sistema
    git
    wget
    curl
    htop
    btop
    tree
    file
    unzip
    zip
    p7zip
    # ripgrep, fd, fzf, bat, eza: movidos a home.packages (rolando.nix).
    # Convención: tools de usuario en home-manager; system solo lleva
    # diagnóstico/emergencia para root y otros eventuales users.
    jq
    yq
    tmux
    gnupg
    pinentry-qt

    # Hardware/disco
    pciutils
    usbutils
    lshw
    smartmontools
    btrfs-progs
    cryptsetup

    # Red
    nmap
    inetutils
    dig
    traceroute

    # Nix tooling
    nix-tree
    nh # wrapper moderno para nixos-rebuild
    nixfmt
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  # ssh-agent a nivel de sesión: cachea la passphrase de la key
  # para que VS Code / Git Graph la usen sin ssh-askpass.
  programs.ssh.startAgent = true;
  # askpass GUI Qt minimalista (reemplaza el x11-ssh-askpass viejo de Motif).
  # Se invoca cuando VS Code / Git Graph piden passphrase sin TTY.
  programs.ssh.askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";

  # nix-ld: provee un loader real en /lib64/ld-linux-x86-64.so.2 para
  # correr binarios dinámicamente linkeados que no fueron empaquetados
  # con autoPatchelfHook. Necesario para Android NDK (clang/ld.lld del
  # SDK descargado por Flutter en ~/Android/Sdk/), VSCode extensions
  # con binarios pre-compilados, etc.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # glibc + libgcc_s — cubre libpthread/librt/libdl/libm/libc
      zlib # libz.so.1
      libxml2 # libxml2.so.2 — usado por ld.lld del NDK
    ];
  };

  # zram swap (50% RAM, comprimido)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # SSD: TRIM semanal (complemento a discard=async)
  services.fstrim.enable = true;
}
