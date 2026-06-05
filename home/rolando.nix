{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.username = "rolando";
  home.homeDirectory = "/home/rolando";
  home.stateVersion = "25.11"; # NO TOCAR después de instalar

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

    # compinit con cache diario: el fpath de NixOS es enorme (paths del store),
    # rescanearlo en cada apertura de shell agrega ~60-80ms al startup.
    # -C salta la verificación de seguridad (segura en NixOS: el store es
    # inmutable y read-only). Re-build completo solo si el dump tiene >24h.
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

      # Nix
      # nh = wrapper de nixos-rebuild con diff coloreado pre/post switch.
      # Detecta el host por hostname (no hace falta #victus).
      rebuild = "nh os switch ~/projects/nix-config";
      rebuild-test = "nh os test ~/projects/nix-config";
      rebuild-boot = "nh os boot ~/projects/nix-config";
      update = "cd ~/projects/nix-config && nix flake update";
      gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

      # btrbk snapshots (@home)
      snap = "sudo btrbk -c /etc/btrbk/home.conf run --progress";
      snap-ls = "sudo btrbk -c /etc/btrbk/home.conf list snapshots";
      snap-dry = "sudo btrbk -c /etc/btrbk/home.conf dryrun";

      # scrcpy con perfil optimizado para Hyprland/Wayland + monitor 144Hz
      # uhid = mouse como HID físico (clicks normales, sin re-mappings).
      # shortcut-mod=lsuper = toggle de captura con Super solo (no choca con grp:alt_shift_toggle).
      # render-driver=opengl = evita stutter del default de SDL3 en Wayland.
      scrcpy = "scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl";

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
      setopt INTERACTIVE_COMMENTS
      unsetopt NOMATCH
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      export ANDROID_SDK_ROOT="/home/rolando/Android/Sdk"
      export ANDROID_HOME="/home/rolando/Android/Sdk"

      # fzf integration cacheada: `fzf --zsh` produce código estático que solo
      # cambia entre versiones. Cacheamos por versión del binario; cuando
      # nixpkgs sube fzf el cache se invalida (path/version del store cambian).
      _fzf_cache="$HOME/.cache/fzf-zsh-${pkgs.fzf.version}.zsh"
      if [[ ! -f "$_fzf_cache" ]]; then
        mkdir -p "$HOME/.cache"
        ${pkgs.fzf}/bin/fzf --zsh > "$_fzf_cache"
      fi
      source "$_fzf_cache"
      unset _fzf_cache

      # tag-gen: crea un git tag con la generation actual de NixOS.
      # Uso: tras un `rebuild` exitoso → `tag-gen` → tagea commit actual como gen-XX.
      # Esto sincroniza historial git ↔ historial de generations del store.
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

  # === starship prompt ===
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # === direnv ===
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # === fzf ===
  # enableZshIntegration = false a propósito: home-manager inyecta
  # `source <(fzf --zsh)` que hace fork+exec en cada init (~10ms). En su lugar
  # cacheamos la salida (estática por versión) en initContent.
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };

  # === Firefox ===
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  # === Cursor: Bibata Modern Classic ===
  # home.pointerCursor configura GTK + XCursor (XWayland) + hyprcursor (Hyprland
  # nativo) en un solo bloque. Sin esto, cada toolkit usa su propio default.
  # `hyprcursor.enable = true` exporta HYPRCURSOR_THEME/SIZE env vars y
  # hace que Hyprland use el cursor vector (más crisp al cambiar de escala).
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  # === Hyprsunset: blue-light filter a nivel de gamma del compositor ===
  # El módulo HM normalmente auto-genera hyprsunset.conf vía xdg.configFile,
  # pero eso choca con nuestro symlink mkOutOfStoreSymlink de `hypr/` completo
  # (HM no puede meter un archivo dentro de un symlink que apunta fuera).
  # Solución: dejamos al módulo encargado del paquete + systemd service,
  # y el config (`hyprsunset.conf`) lo escribimos a mano en dotfiles/hypr/.config/hypr/.
  # IPC en runtime: `hyprctl hyprsunset temperature 3500`.
  services.hyprsunset.enable = true;

  # === Paquetes user-level ===
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

    # Kubernetes (cluster k3s configurado en modules/k3s.nix)
    kubectl # CLI principal de K8s
    k9s # TUI navegable sobre el cluster
    kubernetes-helm # package manager (charts)
    cliphist
    neovim
    python3
    kitty
    hyprlock
    tzdata
    playerctl
    networkmanagerapplet
    libnotify
    yazi

    # Comunicación
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
    nix-output-monitor # nom: árbol de progreso para builds (activado via NH_NOM=1)
    fastfetch
    vscode
    khal # calendario CLI (CalDAV-compat), backend del widget eww
    claude-code
    android-tools
    pavucontrol
    scrcpy

    # Acceso / identity (HashiCorp)
    (callPackage ../pkgs/boundary-desktop.nix { }) # custom: no está en nixpkgs

    # Qt theming: usamos Qt Fusion (built-in, sin engine externo) con paleta
    # configurada via qt6ct. Suficiente para apps Qt efímeras como
    # hyprland-share-picker; el aesthetic "neon islands" del calendar
    # (double box-shadow offset) no es replicable en Qt sin SVG custom.
    kdePackages.qt6ct

    # === Neovim toolchain (LSPs, formatters, linters) ===
    # Build / runtime deps
    gcc # compilar parsers treesitter + telescope-fzf-native
    gnumake
    tree-sitter
    nodejs # base para LSPs/formatters Node

    # CLI utilities de usuario (movidas desde environment.systemPackages).
    # Usadas por aliases (cat=bat, ls/ll=eza) y por Neovim/Telescope.
    bat
    eza
    ripgrep # Telescope live_grep
    fd # Telescope find_files

    # Language servers
    gopls
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted # html, cssls, jsonls, eslint
    yaml-language-server
    bash-language-server
    lua-language-server

    # Formatters (conform.nvim)
    stylua
    ruff
    gofumpt
    (lib.lowPrio gotools) # goimports (lowPrio: gopls gana en /modernize)
    rustfmt
    prettierd # prettier en daemon (más rápido)
    shfmt

    # Linters (nvim-lint)
    golangci-lint
    eslint_d
    shellcheck
    markdownlint-cli
    yamllint
    hadolint
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # Style Qt: Fusion (built-in, sin engine externo). qt6ct lee
    # ~/.config/qt6ct/qt6ct.conf y aplica la paleta neon-islands.
    # QT_QPA_PLATFORMTHEME=qt6ct le dice a Qt6 que use qt6ct para
    # palette/fonts/icons en vez de los defaults.
    QT_STYLE_OVERRIDE = "Fusion";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    EDITOR = "nvim";
    VISUAL = "nvim";
    ANDROID_SDK_ROOT = "/home/rolando/Android/Sdk";
    ANDROID_HOME = "/home/rolando/Android/Sdk";

    # nh detecta NH_NOM=1 y pipea su build output por nix-output-monitor.
    # Resultado: ves el grafo de derivaciones construyéndose en tiempo real
    # (cada nodo = una derivación, barras de progreso, timings).
    NH_NOM = "1";

    # Kubernetes: usar el kubeconfig que escribe k3s en /etc/rancher/k3s/k3s.yaml
    # (modo 644 → legible por user rolando). Permite que `kubectl`/`k9s`/`helm`
    # funcionen sin pasar KUBECONFIG inline.
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  # === Dotfiles como symlinks editables ===
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
  };

  home.file.".config/starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/starship/.config/starship.toml";

  # Override .desktop de Telegram
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
