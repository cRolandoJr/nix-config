{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Reusa el default.nix del repo (hyprlandPlugins.mkHyprlandPlugin).
  # callPackage inyecta hyprland (0.55.2), lua5_4 y hyprlandPlugins desde nixpkgs.
  # overrideAttrs: su default.nix no hereda los buildInputs de hyprland ni expat
  # (lo pide fontconfig vía pkg-config) → los añadimos para que cmake los encuentre.
  scrolloverview =
    (pkgs.callPackage (inputs.scroll-overview + "/default.nix") { }).overrideAttrs
      (old: {
        buildInputs = (old.buildInputs or [ ]) ++ pkgs.hyprland.buildInputs ++ [ pkgs.expat ];
      });
in
{
  home.username = "rolando";
  home.homeDirectory = "/home/rolando";
  home.stateVersion = "25.11"; # no cambiar después de instalar

  programs.home-manager.enable = true;

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

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

    # compinit cacheado: el fpath de NixOS es enorme (~60-80ms sin cache).
    # -C salta el re-scan si el dump tiene <24h (seguro: el store es inmutable).
    completionInit = ''
      autoload -U compinit
      if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
    '';

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

      # nh detecta el host por hostname; no hace falta especificar #victus.
      rebuild = "nh os switch ~/projects/nix-config";
      rebuild-test = "nh os test ~/projects/nix-config";
      rebuild-boot = "nh os boot ~/projects/nix-config";
      update = "cd ~/projects/nix-config && nix flake update";
      gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

      snap = "sudo btrbk -c /etc/btrbk/home.conf run --progress";
      snap-ls = "sudo btrbk -c /etc/btrbk/home.conf list snapshots";
      snap-dry = "sudo btrbk -c /etc/btrbk/home.conf dryrun";

      # uhid: mouse como HID físico. shortcut-mod=lsuper: no choca con alt_shift_toggle.
      # render-driver=opengl: evita stutter de SDL3 en Wayland.
      scrcpy = "scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl";

      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
    };

    initContent = ''
      setopt INTERACTIVE_COMMENTS
      unsetopt NOMATCH
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # starship: init manual (sin programs.starship para que el único dueño de
      # starship.toml sea el mkOutOfStoreSymlink al dotfile, editable en vivo).
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Cache de `fzf --zsh` por versión: evita fork+exec en cada init (~10ms).
      # Se invalida automáticamente cuando nixpkgs sube fzf (path del store cambia).
      _fzf_cache="$HOME/.cache/fzf-zsh-${pkgs.fzf.version}.zsh"
      if [[ ! -f "$_fzf_cache" ]]; then
        mkdir -p "$HOME/.cache"
        ${pkgs.fzf}/bin/fzf --zsh > "$_fzf_cache"
      fi
      source "$_fzf_cache"
      unset _fzf_cache

      # fzf secuestra Tab con fzf-completion, que no incluye dotfiles.
      # Restauramos Tab al completador nativo; fzf sigue en Ctrl+T/R, Alt+C.
      # Debe ir DESPUÉS del source de fzf para ganar el binding.
      bindkey '^I' expand-or-complete

      # globdots: completar dotfiles sin escribir el `.` inicial.
      _comp_options+=(globdots)

      # matcher-list: match exacto → case-insensitive → substring (en orden).
      # "" como string vacío zsh (evita comillas-simples-dobles en Nix).
      zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'

      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'

      # _eza solo ofrece flags, no paths. Forzamos _files para que ls/ll/tree
      # (aliases a eza) completen archivos normalmente.
      compdef _files eza

      # tag-gen: tagea el commit actual con la generation activa del store.
      # Uso: después de un rebuild exitoso → sincroniza git ↔ generations NixOS.
      tag-gen() {
        local repo="$HOME/projects/nix-config"
        local gen
        gen=$(basename "$(readlink /nix/var/nix/profiles/system)" | grep -oE '[0-9]+')
        if [ -z "$gen" ]; then
          echo "tag-gen: no pude leer la generation actual" >&2
          return 1
        fi
        local msg="''${1:-gen $gen — $(date +%Y-%m-%d)}"
        git -C "$repo" tag -a "gen-$gen" -m "$msg" && \
          echo "Tagged gen-$gen → $msg"
      }
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # enableZshIntegration = false: HM inyectaría `source <(fzf --zsh)` con
  # fork+exec en cada init. Usamos el cache manual en initContent en su lugar.
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  # Configura GTK + XCursor + hyprcursor en un solo bloque.
  # hyprcursor.enable exporta las env vars para el cursor vector nativo de Hyprland.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  # El módulo gestiona el paquete + systemd service. El config (hyprsunset.conf)
  # vive en dotfiles/hypr/ porque HM no puede escribir dentro de un mkOutOfStoreSymlink.
  services.hyprsunset.enable = true;

  # Sin botones de ventana en apps libadwaita/GNOME (button-layout vía dconf).
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:";

  # gtk-decoration-layout "appmenu:" = sin botones de ventana (GTK3/4).
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:";
    };
  };

  home.packages = with pkgs; [
    # Hyprland session tools
    rofi
    imagemagick
    waybar
    eww # widgets custom (calendar popup, hub)
    brightnessctl # CLI de brillo de pantalla; usado por slider del hub
    mako
    awww
    hypridle
    swayosd
    thunar
    grim
    slurp
    satty # editor de anotaciones para screenshots (grim | satty)
    wl-clipboard

    # Kubernetes
    kubectl
    k9s
    kubernetes-helm
    cliphist
    neovim
    python3
    kitty
    hyprlock
    tzdata
    networkmanagerapplet
    libnotify
    yazi

    vesktop # cliente Discord Wayland (screen-share con audio)
    telegram-desktop

    obsidian

    # Multimedia
    vlc
    mpv
    spotify

    # Dev
    gh
    lazygit
    httpie
    dust
    duf
    nix-output-monitor # activado via NH_NOM=1
    fastfetch
    vscode
    khal # backend del widget eww de calendario
    # claude-code: gestionado fuera del store (nativo self-updating en ~/.local/bin).
    # nixpkgs va días/semanas detrás de upstream y bloquearía modelos nuevos. Setup en máquina nueva: curl -fsSL https://claude.ai/install.sh | sh
    android-tools
    scrcpy

    (callPackage ../pkgs/boundary-desktop.nix { }) # no está en nixpkgs

    # Qt Fusion (built-in) + qt6ct para paleta en apps Qt efímeras (share-picker, etc.)
    kdePackages.qt6ct

    # Neovim toolchain
    gcc # parsers treesitter + telescope-fzf-native
    gnumake
    tree-sitter
    nodejs

    bat
    eza
    ripgrep # Telescope live_grep
    fd # Telescope find_files

    # LSPs
    gopls
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted # html, css, json, eslint
    yaml-language-server
    bash-language-server
    lua-language-server

    # Formatters
    stylua
    ruff
    gofumpt
    (lib.lowPrio gotools) # goimports; lowPrio para que gopls gane en conflictos
    rustfmt
    prettierd
    shfmt

    # Linters
    golangci-lint
    eslint_d
    shellcheck
    markdownlint-cli
    yamllint
    hadolint
  ];

  # ~/.local/bin: binarios imperativos fuera del store (ej. claude-code nativo).
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0";
    # qt6ct aplica paleta/fonts/icons; Fusion es el engine built-in (sin deps extra).
    QT_STYLE_OVERRIDE = "Fusion";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    EDITOR = "nvim";
    VISUAL = "nvim";
    ANDROID_SDK_ROOT = "/home/rolando/Android/Sdk";
    ANDROID_HOME = "/home/rolando/Android/Sdk";

    NH_NOM = "1"; # nh pipea el build por nix-output-monitor
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"; # k3s escribe este con mode 644
  };

  # Dotfiles como symlinks editables (editar en ~/projects/dotfiles/, no aquí).
  xdg.configFile = {
    "hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/hypr/.config/hypr";

    "waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/waybar/.config/waybar";

    "eww".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/eww/.config/eww";

    "rofi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/rofi/.config/rofi";

    "fastfetch".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/fastfetch/.config/fastfetch";

    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/nvim/.config/nvim";

    "kitty".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/kitty/.config/kitty";

    "mako".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/mako/.config/mako";

    "khal".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/khal/.config/khal";

    "qt6ct".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/qt6ct/.config/qt6ct";

    "yazi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/yazi/.config/yazi";
  };

  home.file.".config/starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/starship/.config/starship.toml";

  # Plugin Hyprland scrolloverview: carga vía archivo generado fuera del symlink
  # de ~/.config/hypr (HM no escribe dentro del mkOutOfStoreSymlink).
  # hyprland.conf lo sourcea; el store-path del .so lo inyecta Nix.
  xdg.configFile."hypr-nix/plugins.conf".text = ''
    plugin = ${scrolloverview}/lib/libscrolloverview.so
  '';

  # Override del .desktop de Telegram (agrega acción "Quit" y corrige WMClass)
  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram";
    comment = "New era of messaging";
    icon = "org.telegram.desktop";
    exec = "Telegram -- %U";
    terminal = false;
    type = "Application";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
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
