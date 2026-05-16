{ config, pkgs, lib, ... }:

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
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "rolando" ];
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
    options = "--delete-older-than 14d";
  };

  # Auto-upgrade del store
  nix.optimise.automatic = true;

  # Unfree packages (drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Usuario rolando
  users.users.rolando = {
    isNormalUser = true;
    description = "Rolando";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"
      "video"
      "audio"
      "libvirtd"        # KVM/QEMU
      "kvm"
      "input"
    ];
    shell = pkgs.zsh;
  };

  # Habilitar zsh a nivel sistema (necesario para users.shell = pkgs.zsh)
  programs.zsh.enable = true;

  # sudo sin password para el grupo wheel (cómodo; sacalo si querés más seguro)
  security.sudo.wheelNeedsPassword = false;

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
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    yq
    tmux

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
    nh                # wrapper moderno para nixos-rebuild
    nixfmt
  ];

  # zram swap (50% RAM, comprimido)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # SSD: TRIM semanal (complemento a discard=async)
  services.fstrim.enable = true;
}
