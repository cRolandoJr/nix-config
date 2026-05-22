{ config, pkgs, lib, inputs, ... }:

{
  home.username = "rolando";
  home.homeDirectory = "/home/rolando";
  home.stateVersion = "25.11"; # NO TOCAR después de instalar

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
      export ANDROID_SDK_ROOT="/home/rolando/Android/Sdk"
      export ANDROID_HOME="/home/rolando/Android/Sdk"
    '';
  };

  # === starship prompt ===
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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

  # === Terminal: kitty ===
 # programs.kitty = {
 #   enable = true;
 #   font = {
 #     name = "JetBrainsMono Nerd Font";
 #     size = 11;
 #   };
 #   settings = {
 #     enable_audio_bell = false;
 #     window_padding_width = 6;
 #     background_opacity = "0.75";
 #     confirm_os_window_close = 0;
 #   };
 #   themeFile = "Catppuccin-Mocha";
 # };

  # === Firefox (config mínima, agregar perfiles después) ===
  programs.firefox = {
  	enable = true;
	configPath = ".mozilla/firefox";
  };

  # === Paquetes user-level (no necesitás recompilar el sistema para cambiarlos) ===
  home.packages = with pkgs; [
    # --- Hyprland session tools ---
    rofi
    imagemagick
    waybar
    mako
    awww
    hypridle
    swayosd
    thunar
    grim
    slurp
    wl-clipboard
    cliphist
    neovim
    python3
    kitty
    hypridle
    hyprlock
    tzdata


    playerctl
    networkmanagerapplet
    # Comunicación (ya tenías)
    discord
    telegram-desktop

    # Productividad
    obsidian
    # Multimedia
    vlc
    mpv
    spotify

    # Dev / utils
    gh
    lazygit
    httpie
    dust
    duf
    fastfetch
    vscode
    claude-code
    android-tools

    # (Recomendado)
    pavucontrol
    stow
    ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    EDITOR = "neovim";
    VISUAL = "neovim";
    ANDROID_SDK_ROOT = "/home/rolando/Android/Sdk";
    ANDROID_HOME = "/home/rolando/Android/Sdk";
  };

# === Dotfiles como symlinks editables ===
xdg.configFile = {
    "hypr".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/hypr/.config/hypr";

    "waybar".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/waybar/.config/waybar";

    "rofi".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/rofi/.config/rofi";

    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/fastfetch/.config/fastfetch";

    "nvim".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/nvim/.config/nvim";

    "kitty".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/projects/dotfiles/kitty/.config/kitty";
  };

  home.file.".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/projects/dotfiles/starship/.config/starship.toml"; 

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
