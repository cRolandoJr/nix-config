

### flake.nix
```nix
{
  description = "rolando NixOS config - victus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.victus = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/victus
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.rolando = import ./home/rolando.nix;
          }
        ];
      };
    };
}
```


### hosts/victus/default.nix
```nix
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
```


### home/rolando.nix
```nix
{ config, pkgs, lib, inputs, ... }:

{
  home.username = "rolando";
  home.homeDirectory = "/home/rolando";
  home.stateVersion = "25.11";   # NO TOCAR después de instalar

  # Programas Home Manager-managed
  programs.home-manager.enable = true;

  # === Git ===
 programs.git = {
    enable = true;
    settings = {
      user.name = "Rolando Cobis";
      user.email = "cobiscalleja@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        excludesfile = "${config.home.homeDirectory}/.gitignore_global";
      };
    };
    includes = [
      {
        condition = "gitdir:~/work/**";
        path = "${config.home.homeDirectory}/work/.gitconfig-empresa";
      }
    ];
  };
     

  # === zsh con plugins ===
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -la --icons --git";
      ls = "eza --icons";
      tree = "eza --tree --icons";
      cat = "bat";

      # Nix
      rebuild = "sudo nixos-rebuild switch --flake ~/projects/nix-config#victus";
      rebuild-test = "sudo nixos-rebuild test --flake ~/projects/nix-config#victus";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/projects/nix-config#victus";
      update = "cd ~/projects/nix-config && nix flake update";
      gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

      # Git rápido
      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
    };

    initContent = ''
      # Prompt: starship lo maneja, no escribimos PS1 acá
      # Mejor uso del historial
      setopt INTERACTIVE_COMMENTS    # permite # como comentario
      unsetopt NOMATCH               # ? y * literales no rompen el comando
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
    '';
  };

  # === starship prompt ===
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # === direnv (carga flakes por proyecto automáticamente) ===
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # === fzf ===
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # === Editor: neovim ===
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = true;
  };

  # === Terminal: kitty ===
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      enable_audio_bell = false;
      window_padding_width = 6;
      background_opacity = "0.95";
      confirm_os_window_close = 0;
    };
    themeFile = "Catppuccin-Mocha";
  };

  # === Firefox (config mínima, agregar perfiles después) ===
  programs.firefox = {
  	enable = true;
	configPath = ".mozilla/firefox";
  };

  # === Paquetes user-level (no necesitás recompilar el sistema para cambiarlos) ===
  home.packages = with pkgs; [
    # Comunicación
    discord
    telegram-desktop

    # Productividad
    obsidian
    #libreoffice-qt6-fresh

    # Multimedia
    vlc
    mpv

    # Dev / utils
    gh                    # GitHub CLI
    lazygit
    httpie
    dust
    duf
    fastfetch
    vscode
    # Capturas y screenshots
    flameshot
  ];

  # Override .desktop de Telegram: KDE no soporta bien DBusActivatable=true del paquete oficial
 xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram";
    comment = "New era of messaging";
    icon = "org.telegram.desktop";
    exec = "Telegram -- %U";
    terminal = false;
    type = "Application";
    categories = [ "Chat" "Network" "InstantMessaging" "Qt" ];
    mimeType = [ "x-scheme-handler/tg" "x-scheme-handler/tonsite" ];
    startupNotify = true;
    settings = {
      TryExec = "Telegram";
      DBusActivatable = "false";
      StartupWMClass = "TelegramDesktop";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;";
    };
    actions.quit = {
      name = "Quit Telegram";
      exec = "Telegram -quit";
      icon = "application-exit";
    };
  };
}
```


### modules/base.nix
```nix
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
    nh                # wrapper moderno para nixos-rebuild
    nixfmt
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
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
```


### modules/desktop-kde.nix
```nix
{ config, pkgs, lib, ... }:

{
  # X11 base (necesario aunque uses Wayland — algunos componentes)
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # SDDM como display manager con Wayland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Excluir apps de KDE que no quiero (podés ajustar la lista)
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa            # reproductor música
    kate             # ya tenés nano/nvim
    khelpcenter
    plasma-browser-integration
  ];

  # Apps KDE útiles que sí quiero
  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    kdeconnect-kde
    partitionmanager
    filelight        # visualizador de uso de disco
    spectacle        # screenshots
    okular           # PDF viewer
    ark              # extractor de archivos
  ];

  # Fuentes
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      jetbrains-mono
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  # Portales (necesarios para Wayland + Flatpak + screen sharing)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs.kdePackages; [
      xdg-desktop-portal-kde
    ];
  };

  # KDEConnect (sync con celular)
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}
```
