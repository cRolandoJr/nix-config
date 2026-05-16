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
      user.name = "rolando";
      user.email = "cobiscalleja@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "vim";
    };
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
    # zoom-us             # descomentá si lo usás

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
    dust                  # du moderno
    duf                   # df moderno

    # Capturas y screenshots
    flameshot
  ];

}
