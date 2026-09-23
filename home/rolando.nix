{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  pedcoBot = inputs.pedco-bot.packages.${pkgs.stdenv.hostPlatform.system}.pedco-bot;
  ryogami = pkgs.callPackage ../pkgs/ryogami { };
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.username = "rolando";
  home.homeDirectory = "/home/rolando";
  home.stateVersion = "25.11"; # no cambiar después de instalar

  programs.home-manager.enable = true;

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets = {
      TG_TOKEN.sopsFile = ../secrets/pedco.yaml;
      # AES-256 base64 (32 bytes). NO cambiar sin migrar la DB.
      SECRET_KEY.sopsFile = ../secrets/pedco.yaml;
      MOODLE_TOKEN.sopsFile = ../secrets/pedco.yaml;
    };
    # Los units piden un EnvironmentFile, no secretos sueltos: el template los
    # compone en un archivo que solo existe descifrado en runtime.
    templates."pedco.env".content = ''
      TG_TOKEN=${config.sops.placeholder.TG_TOKEN}
      SECRET_KEY=${config.sops.placeholder.SECRET_KEY}
    '';
  };

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

      # Lanza el asistente Astro (run.sh carga config + secreto y corre el daemon).
      astro = "~/projects/astro/run.sh";

      # nh detecta el host por hostname; no hace falta especificar #victus.
      rebuild = "nh os switch ~/projects/nix-config";
      rebuild-test = "nh os test ~/projects/nix-config";
      rebuild-boot = "nh os boot ~/projects/nix-config";
      update = "cd ~/projects/nix-config && nix flake update";

      # Una invocación POR unit: sudoers matchea el comando con sus argumentos, así
      # que los dos units juntos no coincidirían con ninguna regla y pediría clave.
      # `;` y no `&&`: los cuatro pasos son independientes y todos deben intentarse
      # (si uno falla, el pkill igual tiene que refrescar custom/gamemode).
      battery-on = "sudo systemctl stop k3s.service; sudo systemctl stop scx.service; powerprofilesctl set power-saver; pkill -RTMIN+11 waybar";
      battery-off = "sudo systemctl start k3s.service; sudo systemctl start scx.service; powerprofilesctl set balanced; pkill -RTMIN+11 waybar";
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
    enable = true;
  };

  # hyprsunset.conf vive en dotfiles/hypr/ (HM no puede escribir dentro del mkOutOfStoreSymlink).
  services.hyprsunset.enable = true;

  # Notifica a mako los eventos de batería de upower (low/critical/carga).
  services.poweralertd.enable = true;

  # Servicio en vez de exec_cmd del autostart: waybar 0.15.0 crashea al perder el
  # audio y con exec_cmd nadie lo relevanta (14 coredumps entre el 15 y el 28-jul).
  # settings/style quedan vacíos a propósito: así el módulo NO escribe el config y
  # sigue mandando el symlink a dotfiles.
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # El reloj de waybar no toma la zona de /etc/localtime; el TZ va explícito.
  systemd.user.services.waybar.Service.Environment = [
    "TZ=America/Argentina/Buenos_Aires"
  ];

  # Launcher: una sola superficie para apps, ventanas, portapapeles, archivos y
  # calculadora. El modulo escribe settings.json y el tema por su cuenta, asi que
  # aca no hay symlink a dotfiles como en el resto del escritorio.
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };

    # La extension de Firefox no esta instalada; el messaging host se enciende
    # el dia que se quieran las pestanas del navegador en el launcher.
    enableFirefoxIntegration = false;

    settings = {
      # Sin font.normal.family a proposito: en 0.23.1 esa clave no se aplica.
      # Medido con tres familias distintas (incluida una serif, para que el
      # cambio fuera imposible de confundir) y con rendering en "qt" y en
      # "native": la UI sigue en la Inter que trae el paquete. font.normal.size
      # SI se aplica, asi que vicinae lee la clave y el que no anda es family.
      launcher_window.layer_shell = {
        enabled = true;
        # El default es "exclusive" y la propia config de vicinae avisa que rompe
        # el mouse de los popups EN HYPRLAND. close_on_focus_loss ademas solo
        # funciona con on_demand, asi que lo uno arrastra lo otro.
        keyboard_interactivity = "on_demand";
      };
      close_on_focus_loss = true;

      # Viene encendido: es monitoreo de input, y existe para pegar en la ventana
      # activa y expandir snippets. Sin snippets no tiene consumidor.
      input_server.enabled = false;

      theme = {
        dark.name = "deep-ocean";
        light.name = "deep-ocean";
      };
    };

    # Los @define-color de la waybar, que es donde vive la paleta. Vicinae pide
    # ocho acentos con nombre y la paleta tiene cinco: los tres que faltan se
    # colapsan sobre estos en vez de sumar colores que no son del escritorio.
    themes.deep-ocean = {
      meta = {
        version = 1;
        name = "Deep Ocean";
        description = "Paleta del escritorio: azul NixOS sobre azul nocturno";
        variant = "dark";
        inherits = "vicinae-dark";
      };
      colors = {
        core = {
          background = "#0a0e17";
          foreground = "#cdd6f4";
          secondary_background = "#0f1623";
          border = "#1a2744";
          accent = "#3b82f6";
        };
        accents = {
          blue = "#3b82f6";
          cyan = "#00b4d8";
          green = "#2d9c6f";
          red = "#f87171";
          orange = "#fb923c";
          yellow = "#fb923c";
          magenta = "#00b4d8";
          purple = "#3b82f6";
        };
      };
    };
  };

  # Como unidad y no como exec_cmd del autostart: ese handler corre solo en
  # `hyprland.start`, y tras un rebuild sin reiniciar sesion los binds fallaban
  # en silencio contra un daemon inexistente.
  systemd.user.services.ryogami = {
    Unit = {
      Description = "Ryogami — daemon de wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${ryogami}/bin/ryogami daemon";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # El orden contra el daemon evita el parpadeo inicial (la superficie
  # reintenta sola, pero arranca en vano hasta que el socket existe).
  systemd.user.services.ryogami-surface = {
    Unit = {
      Description = "Ryogami — superficie que pinta el wallpaper";
      Requires = [ "ryogami.service" ];
      After = [
        "ryogami.service"
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${ryogami}/bin/ryogami-surface";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Bot de Telegram (Pedco): daemon + avisos 8/20h. Binario pineado al store
  # desde inputs.pedco-bot (reemplaza el unit y el nix-profile imperativos).
  systemd.user.services.pedco-bot = {
    Unit = {
      Description = "Pedco Bot (daemon Telegram)";
      # sops-nix.service renderiza el EnvironmentFile: sin este orden, el daemon
      # arranca antes de que exista y falla al bootear.
      Wants = [
        "network-online.target"
        "sops-nix.service"
      ];
      After = [
        "network-online.target"
        "sops-nix.service"
      ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/projects/scraper-pedco";
      EnvironmentFile = config.sops.templates."pedco.env".path;
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
    Unit = {
      Description = "Pedco Bot — ronda de avisos (oneshot)";
      After = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h/projects/scraper-pedco";
      EnvironmentFile = config.sops.templates."pedco.env".path;
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
    # Escritorio: sesión Hyprland, notificaciones, portapapeles, terminal, archivos
    # Los plugins van por override y no como paquetes sueltos: rofi solo carga
    # los .so que tiene en su propio wrapper.
    (rofi.override {
      plugins = [
        rofi-calc # modo `calc`: 1920/2.5 dentro del propio lanzador
      ];
    })
    eww # widgets custom (calendar popup, hub)
    mako
    awww
    hypridle
    hyprlock
    swayosd
    cliphist
    wl-clipboard
    brightnessctl # CLI de brillo; usado por el slider del hub
    libnotify
    kdePackages.qt6ct # paleta en apps Qt efímeras (share-picker); Qt Fusion es built-in
    foot
    thunar
    yazi

    # Capturas de pantalla
    grim
    slurp
    satty # anotar: grim | satty
    imagemagick

    # Multimedia
    vlc
    mpv
    spotify
    sox
    cava # ecualizador del reproductor del hub; lo lanza eww/scripts/cava-mpris.sh

    # Ocio y comunicación
    telegram-desktop
    discord
    google-chrome

    # Productividad
    obsidian
    libreoffice
    khal # calendario local; TUI ikhal en SUPER+I (el widget de eww no lo usa)
    tzdata

    # Dev: editores y git
    neovim
    vscode
    antigravity-ide
    gh
    lazygit

    # Dev: CLI
    bat
    eza
    ripgrep # Telescope live_grep
    fd # Telescope find_files
    httpie
    poppler-utils
    fastfetch
    nix-output-monitor # activado via NH_NOM=1

    # Infra: secretos
    sops # editar secretos: sops secrets/pedco.yaml
    ssh-to-age # derivar el recipient age de la SSH

    # Infra: k3s single-node (modules/k3s.nix; el servicio arranca a mano)
    kubectl
    k9s
    kubernetes-helm

    # Infra: Android
    android-tools
    scrcpy

    # Fuera de nixpkgs
    (callPackage ../pkgs/boundary-desktop.nix { }) # no está en nixpkgs
    (callPackage ../pkgs/balena-etcher.nix { }) # ídem; removido de nixpkgs
    ryogami # vendorizado de Ryoku, con parches propios (ver el let)

    # Python + CodeGraphContext
    python3

    # CGC requiere python3.12 (excluye tree-sitter en 3.13); lowPrio evita colisión
    # con python3 en nombres genéricos (bin/python3, etc.).
    # WORKAROUND nixpkgs 26-jul-2026: tests/test_inject.py de pipx 1.14.0 no collecta con el
    # pytest actual (parametrize con string); el `disabledTests` de nixpkgs es -k y corre
    # post-collection, así que no alcanza. Retirar cuando `pipx` plano vuelva a buildear.
    (pipx.overridePythonAttrs (o: {
      disabledTestPaths = (o.disabledTestPaths or [ ]) ++ [ "tests/test_inject.py" ];
    }))
    (lib.lowPrio python312)

    # CGC (FalkorDB Lite) hace dlopen de libstdc++.so.6, ausente en rutas FHS de NixOS.
    # Este wrapper inyecta gcc-lib solo al proceso CGC; cgc-nix evita colisión con el binario de pipx.
    (writeShellScriptBin "cgc-nix" ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec "$HOME/.local/share/pipx/venvs/codegraphcontext/bin/codegraphcontext" "$@"
    '')

    # Neovim toolchain
    gcc # parsers treesitter + telescope-fzf-native
    gnumake
    tree-sitter
    nodejs

    # LSPs
    go # gopls resuelve root_dir con 'go env GOMODCACHE'; sin toolchain rompe en buffers Go
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
    MOODLE_URL = "https://pedco.uncoma.edu.ar/webservice/rest/server.php";

    NH_NOM = "1"; # nh pipea el build por nix-output-monitor
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"; # k3s escribe este con mode 644
    GOVERNANCE_USER_HANDLE = "rc"; # sin esto los scripts de gama23 resuelven a roddy
  };

  xdg.configFile = {
    "hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/hypr/.config/hypr";

    "waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/waybar/.config/waybar";

    "eww".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/eww/.config/eww";

    "cliphist".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/cliphist/.config/cliphist";

    "rofi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/rofi/.config/rofi";

    "fastfetch".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/fastfetch/.config/fastfetch";

    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/nvim/.config/nvim";

    "quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/quickshell/.config/quickshell";

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
  # ─────────────────────────────────────────────────────────────────────
  # El daemon y el selector leen archivos distintos, y escribir en el que no es
  # no da error: da silencio. Se tocan solo las claves estructurales y quedan
  # escribibles, porque el selector guarda ahi sus favoritos; la contrapartida es
  # que editarlas a mano no sobrevive al proximo rebuild. La logica va en un
  # script porque con $DRY_RUN_CMD las redirecciones se ejecutan igual.
  home.activation.ryogamiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.writeShellScript "ryogami-config" ''
      set -eu
      daemon_cfg="$HOME/.config/ryoku/ryogami.json"
      picker_cfg="$HOME/.config/ryogami-wall/config.json"

      mkdir -p "$HOME/.config/ryoku" "$HOME/.config/ryogami-wall"
      [ -f "$daemon_cfg" ] || echo '{}' > "$daemon_cfg"
      [ -f "$picker_cfg" ] || echo '{}' > "$picker_cfg"

      # El daemon NO expande `~`: con "~/Wallpapers" devuelve cero wallpapers y
      # no avisa. Por eso la ruta se interpola absoluta desde Nix.
      ${pkgs.jq}/bin/jq '.paths.wallpaper = "${config.home.homeDirectory}/Wallpapers"
        | .features.matugen = false' "$daemon_cfg" > "$daemon_cfg.new"
      mv "$daemon_cfg.new" "$daemon_cfg"

      # matugen en false a proposito: sus plantillas escriben temas en
      # ~/.config/{kitty,yazi,qt6ct}. Hoy no rompe nada porque home-manager deja
      # esas rutas de solo lectura, pero no conviene depender de eso.
      ${pkgs.jq}/bin/jq '.paths.wallpaper = "${config.home.homeDirectory}/Wallpapers"
        | .components.wallpaperSelector.displayMode = "slices"
        | .features.matugen = false
        | .transition = {enabled: true, shader: "random", durationMs: 600}' \
        "$picker_cfg" > "$picker_cfg.new"
      mv "$picker_cfg.new" "$picker_cfg"
    ''}
  '';
}
