{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  pedcoBot = inputs.pedco-bot.packages.${pkgs.stdenv.hostPlatform.system}.pedco-bot;
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

    # compinit -C: saltea re-scan si dump tiene <24h (~60-80ms ganados con el fpath enorme de NixOS).
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

      # init manual: programs.starship pisaría el starship.toml del mkOutOfStoreSymlink.
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Cache por versión: evita fork+exec en cada init (~10ms); se invalida al subir fzf en nixpkgs.
      _fzf_cache="$HOME/.cache/fzf-zsh-${pkgs.fzf.version}.zsh"
      if [[ ! -f "$_fzf_cache" ]]; then
        mkdir -p "$HOME/.cache"
        ${pkgs.fzf}/bin/fzf --zsh > "$_fzf_cache"
      fi
      source "$_fzf_cache"
      unset _fzf_cache

      # fzf secuestra Tab; restauramos al completador nativo (después del source para ganar el binding).
      bindkey '^I' expand-or-complete

      _comp_options+=(globdots)

      # "" vacío como primer patrón: exacto → case-insensitive → substring.
      zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'

      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'

      # _eza solo ofrece flags; _files para que ls/ll/tree completen paths.
      compdef _files eza

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

  # enableZshIntegration = false: se usa cache manual en initContent (ver arriba).
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  # hyprsunset.conf vive en dotfiles/hypr/ (HM no puede escribir dentro del mkOutOfStoreSymlink).
  services.hyprsunset.enable = true;

  # Notifica a mako los eventos de batería de upower (low/critical/carga).
  services.poweralertd.enable = true;

  # Bot de Telegram (Pedco): daemon + avisos 8/20h. Binario pineado al store
  # desde inputs.pedco-bot (reemplaza el unit y el nix-profile imperativos).
  systemd.user.services.pedco-bot = {
    Unit = {
      Description = "Pedco Bot (daemon Telegram)";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/projects/scraper-pedco";
      EnvironmentFile = "%h/projects/scraper-pedco/.env";
      ExecStart = "${pedcoBot}/bin/pedco-bot";
      Restart = "always";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Oneshot disparado por el timer (sin WantedBy propio): una ronda y sale.
  systemd.user.services.pedco-bot-notify = {
    Unit.Description = "Pedco Bot — ronda de avisos (oneshot)";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h/projects/scraper-pedco";
      EnvironmentFile = "%h/projects/scraper-pedco/.env";
      ExecStart = "${pedcoBot}/bin/pedco-bot notify";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  # Persistent=true: si la laptop estaba apagada/suspendida a las 8/20h, dispara
  # el aviso al volver — el catch-up que al cron interno le faltaba.
  systemd.user.timers.pedco-bot-notify = {
    Unit.Description = "Pedco Bot — avisos 8:00 y 20:00 (con catch-up)";
    Timer = {
      OnCalendar = [
        "*-*-* 08:00:00"
        "*-*-* 20:00:00"
      ];
      Persistent = true;
      RandomizedDelaySec = "30";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:";

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

    # CGC requiere python3.12 (excluye tree-sitter en 3.13); lowPrio evita colisión
    # con python3 en nombres genéricos (bin/python3, etc.).
    pipx
    (lib.lowPrio python312)

    # CGC (FalkorDB Lite) hace dlopen de libstdc++.so.6, ausente en rutas FHS de NixOS.
    # Este wrapper inyecta gcc-lib solo al proceso CGC; cgc-nix evita colisión con el binario de pipx.
    (writeShellScriptBin "cgc-nix" ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec "$HOME/.local/share/pipx/venvs/codegraphcontext/bin/codegraphcontext" "$@"
    '')

    foot
    hyprlock
    tzdata
    networkmanagerapplet
    libnotify
    yazi

    telegram-desktop
    discord

    obsidian
    onlyoffice-desktopeditors

    # Multimedia
    vlc
    mpv
    spotify

    # Dev
    gh
    lazygit
    opencode
    httpie
    dust
    duf
    nix-output-monitor # activado via NH_NOM=1
    fastfetch
    vscode
    khal # backend del widget eww de calendario
    chromium

    # claude-code: nativo self-updating en ~/.local/bin (ver memory). Setup: curl -fsSL https://claude.ai/install.sh | sh
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

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0";
    QT_STYLE_OVERRIDE = "Fusion";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    EDITOR = "nvim";
    VISUAL = "nvim";
    ANDROID_SDK_ROOT = "/home/rolando/Android/Sdk";
    ANDROID_HOME = "/home/rolando/Android/Sdk";

    NH_NOM = "1"; # nh pipea el build por nix-output-monitor
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"; # k3s escribe este con mode 644
  };

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

    "foot".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/foot/.config/foot";

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
