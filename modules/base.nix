{
  config,
  pkgs,
  lib,
  ...
}:

{
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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
    "vm.swappiness" = 180; # zram
    "vm.page-cluster" = 0; # zram
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  # madvise: evita compactación global (stutter en juegos).
  boot.kernelParams = [ "transparent_hugepage=madvise" ];

  nixpkgs.config.allowUnfree = true;

  users.users.rolando = {
    isNormalUser = true;
    description = "Rolando";
    extraGroups = [
      "wheel"
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

  programs.zsh.enable = true; # necesario para users.shell = pkgs.zsh

  security.sudo = {
    wheelNeedsPassword = true;
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
          # Toggle del perfil battery sin eval ni generación nueva (aliases
          # battery-on/off). Solo el arg "switch": no habilita boot/test/etc.
          {
            command = "/run/current-system/specialisation/battery/bin/switch-to-configuration switch";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/var/nix/profiles/system/bin/switch-to-configuration switch";
            options = [ "NOPASSWD" ];
          }
          # Botón "modo juego" de waybar: k3s idle come 6.7% de CPU y 539 MiB
          # (medido 28-jul). sudoers exige match exacto del comando COMPLETO, así
          # que esto no habilita systemctl genérico — solo estas dos unidades.
          {
            command = "/run/current-system/sw/bin/systemctl stop k3s.service";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start k3s.service";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    nano
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
    jq
    yq
    tmux
    gnupg
    pinentry-qt

    pciutils
    usbutils
    lshw
    smartmontools
    btrfs-progs
    cryptsetup

    nmap
    inetutils
    dig
    traceroute

    nix-tree
    nh
    nixfmt
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  programs.ssh.startAgent = true;
  programs.ssh.askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libpthread/librt/libdl/libm/libc
      zlib
      libxml2 # ld.lld del NDK
    ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  services.fstrim.enable = true; # complemento a discard=async

  # Mide batería y emite eventos low/critical; poweralertd (home) los notifica.
  services.upower.enable = true;
}
