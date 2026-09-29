# Guía práctica de NixOS — Instalar, configurar, debuggear

Referencia para tu flake en `~/projects/nix-config/`. No es la documentación oficial, es el flujo mental para tomar decisiones rápido.

---

## 0. Decision tree — antes de tocar nada

Cuando quieras "instalar X" en NixOS, contestate **estas 3 preguntas** en orden:

```
1. ¿Es un paquete (binario que ejecuto) o una configuración (servicio/feature)?
     │
     ├── Paquete simple ──> ir a la pregunta 2
     │
     └── Algo con config integrada (daemon, hardware, programa con opciones)
            └── Buscar opción en search.nixos.org/options
                   ej: services.k3s.*, programs.firefox.*, hardware.bluetooth.*

2. Si es paquete: ¿es para vos (user) o para todo el sistema (root también)?
     │
     ├── User-level ──> home.packages en home/rolando.nix
     │
     └── System-wide ──> environment.systemPackages en module

3. ¿El paquete tiene un módulo programs.X o services.X que lo configure?
     │
     ├── Sí, y querés usar la config integrada ──> usar el módulo
     │     (ej: programs.zsh.enable = true; en vez de solo poner zsh en packages)
     │
     └── No, o solo querés el binario ──> packages
```

**Regla práctica:** si solo lo vas a ejecutar a mano (`kubectl`, `yt-dlp`, `bat`), va en packages. Si corre como daemon o tiene config (`nginx`, `k3s`, `openssh`, `firefox`), buscá el módulo.

---

## 1. Las 2 bases de datos que tenés que conocer

NixOS expone **dos catálogos distintos**. Buscar en el equivocado es el error más común al arrancar.

| Catálogo | Para qué sirve | Dónde se busca | Comando local |
|---|---|---|---|
| **Packages** | Listado de binarios disponibles (~120k) | https://search.nixos.org/packages | `nix search nixpkgs <nombre>` |
| **Options** | Opciones declarativas (servicios, hardware, programas configurables) | https://search.nixos.org/options | `man configuration.nix` (system), `man home-configuration.nix` (user) |

### Ejemplo concreto de ambas

Querés instalar k3s. Antes de editar, buscás:

- **search.nixos.org/packages** → `k3s` → te dice que el paquete existe y la versión.
- **search.nixos.org/options** → `services.k3s` → te muestra **todas** las opciones del módulo (`enable`, `role`, `tokenFile`, `extraFlags`, etc.) con tipo, default y descripción.

Como k3s es un *daemon*, lo que te importa es el segundo: lo vas a configurar con `services.k3s.enable = true;`, no con un `environment.systemPackages = [ k3s ];` pelado.

### `nix search` cuando no tenés internet

```bash
nix search nixpkgs satty
# evaluating 'satty' ...
# * legacyPackages.x86_64-linux.satty (0.20.0)
#   Modern Screenshot Annotation. A Screenshot Annotation Tool inspired by Swappy and Flameshot
```

Tarda en la primera corrida (descarga el index), después es instantáneo.

---

## 2. Los 2 lugares donde declarás cambios

Tu repo está modularizado así:

```
~/projects/nix-config/
├── flake.nix                       # inputs (nixpkgs, home-manager, etc.)
├── hosts/
│   └── victus/                     # config específica del laptop
├── modules/
│   ├── desktop-hyprland.nix        # módulos system-level
│   └── ...                         # podés crear más (ej: k3s.nix)
└── home/
    └── rolando.nix                 # config user-level (home-manager)
```

### Cuándo va en cada uno

| Va en `modules/` o `hosts/` (system) | Va en `home/` (user) |
|---|---|
| Daemons que corren con systemd y necesita todos los usuarios (sshd, nginx, k3s) | CLI tools tuyos (kubectl, k9s, bat, eza) |
| Hardware (bluetooth, sound, gráficos) | GUI apps (firefox, discord, obsidian) |
| Display manager, kernel, filesystems | Dotfiles, temas, shell config |
| Polkit, firewall, paquetes que necesita root | Editores y sus configs (neovim, vscode) |
| Usuarios del sistema | Plugins/extensiones de tus programas |

**Regla:** ¿necesita correr antes de que vos hagas login? → system. ¿Solo lo usás vos cuando trabajás? → user.

**Gris:** `kubectl` puede ir en cualquiera. Si trabajás solo vos en la laptop, ponelo en `home/`. Si hipotéticamente otro user del sistema lo necesitara, en `modules/`.

---

## 3. Los 6 patrones reales con ejemplos

Estos son los patrones que vas a usar el 95% del tiempo. Cada uno con un ejemplo **sacado de tu repo** + uno nuevo que podrías sumar.

### Patrón A — CLI tool user-level

**Cuándo:** un binario que solo usás vos, sin daemon ni config compleja.

**Dónde:** `home/rolando.nix` → `home.packages`

**Ejemplo de tu repo** (`home/rolando.nix`):

```nix
home.packages = with pkgs; [
  rofi
  bat
  eza
  fd
  ripgrep
  satty
  yazi
];
```

**Para sumar uno nuevo** (ej: `zoxide`):

```nix
home.packages = with pkgs; [
  # ...lo que ya tenés
  zoxide              # cd inteligente
];
```

**Tip:** el `with pkgs;` arriba del bloque te permite escribir `zoxide` en vez de `pkgs.zoxide`. Es azúcar sintáctico.

---

### Patrón B — GUI app user-level

**Cuándo:** una aplicación gráfica para vos solo.

**Dónde:** igual que A — `home.packages`. NixOS no distingue entre CLI y GUI; el binario es un binario.

**Ejemplo de tu repo:**

```nix
home.packages = with pkgs; [
  discord
  telegram-desktop
  obsidian
  spotify
];
```

---

### Patrón C — Programa con módulo (config integrada)

**Cuándo:** el paquete tiene opciones declarativas (`programs.X.*`) que reemplazan editar archivos a mano.

**Dónde:** mismo nivel que el resto del módulo (system o user).

**Ejemplo de tu repo** (`home/rolando.nix`, bloque `programs.firefox`):

```nix
programs.firefox = {
  enable = true;
  configPath = ".mozilla/firefox";
};
```

Esto **además de instalar firefox**, configura el path del profile. Sumar `firefox` a `home.packages` *sin* el módulo te instala el binario pero no toca el profile.

**Otro de tu repo** (`modules/desktop-hyprland.nix`, bloque `programs.hyprland`):

```nix
programs.hyprland = {
  enable = true;
  withUWSM = true;
};
```

`enable = true;` instala el paquete, agrega el .desktop a /usr/share/wayland-sessions, levanta los portals que necesita. Hacerlo a mano son ~15 líneas más.

**Cómo descubrir si un paquete tiene módulo:** en search.nixos.org/options buscás `programs.<nombre>` o `services.<nombre>`. Si aparece, hay módulo — usalo en vez de packages.

---

### Patrón D — System-wide CLI tools

**Cuándo:** una herramienta de admin que tiene que estar disponible para root también, o para todos los users.

**Dónde:** `environment.systemPackages` en un módulo o en `hosts/victus/configuration.nix`.

**Ejemplo de tu repo** (`modules/desktop-hyprland.nix`, bloque `environment.systemPackages`):

```nix
environment.systemPackages = with pkgs; [
  polkit_gnome
  qalculate-gtk
  gparted
  baobab
  zathura
  kdePackages.kdeconnect-kde
  sddmAstronaut
];
```

**Tip:** `polkit_gnome` está acá (no en home) porque su agent tiene que arrancar como servicio para todo el sistema y necesita estar visible globalmente.

---

### Patrón E — Servicio del sistema (daemon)

**Cuándo:** algo que corre como servicio systemd, escucha en puertos, gestiona estado, etc.

**Dónde:** módulo system-level, usando `services.X.enable`.

**Ejemplo de tu repo** (`modules/desktop-hyprland.nix`, bloque `services.displayManager.sddm`):

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = false;
  theme = "sddm-astronaut-theme";
  extraPackages = [ sddmAstronaut pkgs.kdePackages.qtmultimedia ];
  settings.General.InputMethod = "";
};
```

Este patrón **declara el servicio entero**: NixOS genera la unit de systemd, el config file y la integración con el resto del sistema.

**Ejemplo de uno que vamos a hacer** (k3s):

```nix
services.k3s = {
  enable = true;
  role = "server";                 # single-node = server + agent embebido
  extraFlags = [ "--disable=traefik" ];   # opcional, sacar traefik si querés ingress propio
};

networking.firewall.allowedTCPPorts = [ 6443 ];   # API server
```

**Tip:** si la opción no aparece en search.nixos.org/options/services.X, no existe. No te la inventes — proba `nixos-option services.X` para listar todas.

---

### Patrón F — Servicio user (systemd --user)

**Cuándo:** un daemon que corre solo en tu sesión gráfica (no necesita root), depende de variables como `WAYLAND_DISPLAY`.

**Dónde:** module system (atado a tu user), usando `systemd.user.services.X`.

**Ejemplo de tu repo** (`modules/desktop-hyprland.nix`):

```nix
systemd.user.services.notify-layout = {
  description = "Hyprland keyboard layout change notifier";
  wantedBy = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  partOf = [ "graphical-session.target" ];
  path = with pkgs; [ bash nmap libnotify ];   # nmap trae ncat (socat no está en PATH)
  serviceConfig = {
    Type = "simple";
    ExecStart = "%h/.config/hypr/scripts/notify-layout.sh";   # %h = $HOME del usuario
    Restart = "on-failure";
    RestartSec = 5;
    StartLimitBurst = 5;
    StartLimitIntervalSec = 60;
  };
};
```

**Diferencia clave con E:** este unit corre como `rolando`, no como root. Lo manejás con `systemctl --user`, no `sudo systemctl`.

**Por qué `%h` y no `/home/rolando/`:** `%h` es un *specifier* de systemd que se expande al `$HOME` del usuario que corre el unit. Si el módulo se reutiliza en otro host o el username cambia, sigue funcionando sin edición. Con paths hardcodeados, el módulo queda atado a una persona concreta. Otros specifiers útiles: `%u` (nombre de usuario), `%H` (hostname), `%n` (nombre del unit). Ver `man systemd.unit` → sección *Specifiers*.

---

## 3.5 Regla de organización: ¿dónde va un paquete?

La duplicación (mismo paquete en `home.packages` Y en `environment.systemPackages`) ocupa espacio y genera confusión. La regla con una pregunta concreta:

> **"¿Si root se loguea en una TTY de emergencia (sin Wayland, sin home-manager), necesitaría esta herramienta?"**

- **Sí** → `environment.systemPackages`. Casos: `vim`, `htop`, `git`, `lshw`, `smartmontools`, herramientas de diagnóstico de hardware.
- **No** → `home.packages`. Casos: `bat`, `eza`, `fzf`, `ripgrep`, `fd`, `yazi` — útiles para vos, pero no en emergencias de sistema.

Si un paquete está en ambos, hay duplicación innecesaria. Elegí uno y retiralo del otro.

---

## 4. Patrones más avanzados (te van a aparecer eventualmente)

### Hardware

```nix
hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
};

hardware.graphics = {
  enable = true;
  extraPackages = with pkgs; [ intel-media-driver vaapiIntel ];   # VAAPI
};
```

### Fonts (system-wide)

```nix
fonts.packages = with pkgs; [
  jetbrains-mono
  nerd-fonts.jetbrains-mono
  noto-fonts
  noto-fonts-emoji
];
```

### Plugins de un programa configurable

Hyprland plugin via flake input:

```nix
# flake.nix
inputs.hyprland-plugins.url = "github:hyprwm/hyprland-plugins";

# modules/desktop-hyprland.nix
programs.hyprland.plugins = [
  inputs.hyprland-plugins.packages.${pkgs.system}.hy3
];
```

### Override de un paquete (cambiar versión, flags, etc.)

```nix
let
  miNeovim = pkgs.neovim.override {
    withPython3 = false;
    extraLuaPackages = lp: [ lp.luarocks ];
  };
in {
  home.packages = [ miNeovim ];
}
```

### Pin a versión específica (overlay)

```nix
nixpkgs.overlays = [
  (final: prev: {
    discord = prev.discord.overrideAttrs (old: {
      version = "0.0.123";
      src = builtins.fetchurl { url = "..."; sha256 = "..."; };
    });
  })
];
```

### Archivos declarativos en `~/.config` (home-manager)

```nix
# Tu mismo patrón en home/rolando.nix (dentro de xdg.configFile)
xdg.configFile."mako".source = config.lib.file.mkOutOfStoreSymlink
  "${config.home.homeDirectory}/projects/dotfiles/mako/.config/mako";
```

`mkOutOfStoreSymlink` apunta a un path **mutable** (tus dotfiles), así editás libremente. Sin eso, home-manager genera un symlink al store (read-only).

---

## 5. El ciclo de cambio

### Workflow moderno: alias + `nh`

Tu flujo habitual usa tres alias definidos en `home/rolando.nix`:

| Alias | Expande a | Cuándo |
|---|---|---|
| `rebuild` | `nh os switch ~/projects/nix-config` | Compilar, activar como generación actual |
| `rebuild-test` | `nh os test ~/projects/nix-config` | Activar temporalmente — se pierde al reboot |
| `rebuild-boot` | `nh os boot ~/projects/nix-config` | Dejar listo para el próximo boot (kernel, initrd) |

Flujo recomendado:

```bash
rebuild-test    # ¿compila y funciona?
rebuild         # si OK, lo fijás como generación actual
git commit      # el commit queda embutido en la generación (ver 5.1)
```

**Por qué `nh` en vez de `sudo nixos-rebuild switch --flake ...`:**
`nh` es un wrapper que antes de aplicar te muestra un diff coloreado de paquetes (qué se agrega, qué se saca, qué cambia de versión) — comparable al `terraform plan` antes de un `apply`. También tiene output más legible que el scroll de hashes de nixos-rebuild.

### `NH_NOM=1` — visualización del build en tiempo real

```bash
NH_NOM=1 rebuild       # activa nix-output-monitor (nom)
```

Cuando `NH_NOM=1` está definido, `nh` detecta la variable y pipa su output por `nix-output-monitor` (nom). En vez de un scroll de rutas del store, ves un árbol de derivaciones que se va construyendo en vivo — cuántos están en caché, cuáles están compilando, tiempo estimado.

**Por qué no es el default:** nom agrega overhead y puede esconder mensajes de error si algo falla early. Para rebuilds complejos o cuando querés ver progreso: activalo. Para debugging de errores: mejor sin él.

### Referencia completa de comandos `nh`

```bash
nh os switch ~/projects/nix-config       # = sudo nixos-rebuild switch --flake ...#victus
nh os boot   ~/projects/nix-config       # = boot
nh os test   ~/projects/nix-config       # = test
nh os build  ~/projects/nix-config       # compila sin activar (deja ./result)
nh search ripgrep                        # busca paquetes en TUI interactiva
nh clean all --keep 5                    # limpia generaciones, guarda las últimas 5
```

Para home-manager solo (sin tocar sistema) — útil si solo cambiaste `home/rolando.nix`:

```bash
home-manager switch --flake ~/projects/nix-config
```

Como home-manager está integrado al flake del sistema, `rebuild` ya lo levanta todo. Usá `home-manager switch` solo si querés iterar rápido en dotfiles sin tocar módulos system.

### `switch` vs `boot`: cuándo cada uno (evitar logout)

Esta distinción importa más de lo que parece. Cuando hacés `nixos-rebuild switch`, NixOS no solo crea la generación nueva: corre la **fase de activación** (`switch-to-configuration switch`), que **reinicia los servicios systemd cuyas dependencias cambiaron** — en caliente, sobre tu sesión activa.

Si el cambio toca el **stack gráfico base** (Mesa, wayland, libdrm, dbus, pipewire, xdg-desktop-portal, o el propio Hyprland), reiniciar esos servicios **arrastra tu sesión gráfica → logout**. No es un crash: es el activador pisando servicios de los que depende tu sesión Wayland.

`boot` evita esto: construye la generación y la deja como default del bootloader, pero **NO toca tu sesión actual**. El stack nuevo se carga limpio en el próximo arranque.

| Tipo de cambio | Comando | Por qué |
|---|---|---|
| Editar dotfile, agregar paquete CLI | `rebuild` (switch) | Cambio chico, no toca la sesión gráfica |
| `nix flake update` (update de canal) | `rebuild-boot` + `reboot` | Puede traer kernel/Mesa nuevos → reboot limpio |
| Cambio de canal (stable↔unstable) o upgrade de release | `rebuild-boot` + `reboot` | Garantiza stack gráfico coherente, sin logout a mitad de activación |
| Tocar kernel, drivers GPU, gráficos | `rebuild-boot` + `reboot` | Evita módulos del kernel viejo descargados mientras corrés uno nuevo |

**Síntoma típico del salto stable→unstable:** el primer `switch` hace logout (descarga mucho + reinicia gráficos), un segundo `switch` puede hacer logout otra vez sin crear generación nueva (completa una activación que quedó a medias), y recién el tercero corre limpio. Todo eso se evita con `rebuild-boot` + `reboot` desde el principio para cambios grandes.

**Detalle del kernel:** si un `flake update` trae kernel nuevo y hacés `switch`, los módulos del kernel viejo pueden quedar descargados mientras corrés el binario nuevo → fallan cosas como USB, suspend o el touchpad hasta que reinicies. Otra razón para `boot` en updates de canal.

---

## 5.1 Versionado: qué commit es la generación que estoy corriendo

**El problema:** cada `rebuild` crea una generación numerada en `/nix/var/nix/profiles/system-NN-link`. Podés bootear la gen 130 desde el menú. Pero una vez adentro, ¿qué commit de git *es* esa gen 130? Sin registro, perdés el hilo justo cuando más lo necesitás — cuando algo se rompió y estás en una generación vieja tratando de entender qué cambió.

**La solución: `system.configurationRevision`.** Una línea en el flake que embute el commit en **cada** generación:

```nix
# flake.nix, dentro de los modules de nixosSystem
{ system.configurationRevision = self.rev or self.dirtyRev or "dirty"; }
```

```bash
nixos-version --configuration-revision
# → e45ce6939a01b1e5...            (árbol limpio: el SHA del commit)
# → 1584012168ae...-dirty          (con cambios sin commitear)
```

La cadena `self.rev or self.dirtyRev or "dirty"` importa: `self.rev` **solo existe si el árbol está limpio**. Sin el fallback, evaluar con cambios sin commitear tira error.

**Por qué se consulta desde adentro y eso es la clave:** booteaste una generación vieja porque la nueva rompió. Estás en esa sesión. `nixos-version --configuration-revision` te dice el commit sin depender de nada externo — ni de que te hayas acordado de anotar algo, ni de tener el repo a mano.

> **Histórico — por qué se descartó `tag-gen`.** Antes había una función zsh que creaba un tag `gen-NN` a mano tras cada rebuild exitoso. Se removió el 28-jul-2026 con datos: **9 tags sobre 144 generaciones (6% de cobertura)**, y las tres que se revisaron (`gen-96`, `gen-109`, `gen-123`) ya habían sido GC-eadas — o sea que ningún tag apuntaba a una generación booteable. Un registro que depende de acordarse no es un registro. La lección general: si algo requiere un paso manual repetido para tener valor, medí la cobertura real antes de confiar en él.

---

## 5.2 Pre-commit hooks: calidad automática del flake

**El problema:** es fácil commitear Nix con typos de formato (tabs vs espacios), anti-patrones, o variables no usadas. Cuando el error lo encontrás en el rebuild, ya perdiste tiempo.

**La solución:** `pre-commit-hooks.nix` ejecuta validaciones automáticamente antes de que git acepte el commit.

### Cómo funciona en tu setup

Tu `flake.nix` tiene:
1. Un input `pre-commit-hooks.nix` que provee las herramientas.
2. Un `devShell` cuyo `shellHook` instala `.git/hooks/pre-commit` automáticamente.
3. Un `.envrc` en el root del repo con `use flake`, que activa el devShell al entrar al directorio.

El resultado: cuando entrás a `~/projects/nix-config/`, direnv activa el devShell, que instala el hook. Al hacer `git commit`, el hook corre antes de que git escriba el commit.

### Los tres hooks activos

| Hook | Herramienta | Qué detecta |
|---|---|---|
| **nixfmt** | nixfmt-rfc-style | Formato según RFC 166 (el estándar oficial de Nix) |
| **statix** | statix | Anti-patrones: `let x = ...; in x`, `with pkgs; with lib;` anidados, etc. |
| **deadnix** | deadnix | Bindings declarados pero nunca usados |

### Configuraciones especiales que tenés

**`statix.toml`** en el root (sin punto inicial — statix no acepta `.statix.toml`):

```toml
[checks]
disabled = ["repeated_keys"]
```

La regla W20 (`repeated_keys`) detecta cuando usás `services.X` y `services.Y` en el mismo scope. El problema es que rompe la legibilidad cuando intercalás comentarios largos entre dos bloques del mismo namespace. La tenés deshabilitada conscientemente.

**`deadnix.settings.noLambdaPatternNames = true`** en flake.nix: ignora los argumentos `{ config, pkgs, lib, ... }` no usados. Es convención de NixOS declarar todos aunque no uses todos en cada módulo.

### Cuándo regenerar el hook

Si cambiás la configuración de los hooks en `flake.nix`, el archivo `.git/hooks/pre-commit` instalado queda desactualizado. Para regenerarlo:

```bash
nix develop --command true
# "true" es el comando más mínimo posible — solo activa el devShell y sale
# el shellHook ya re-instaló el hook
```

Para validar todos los archivos de una vez sin commitear:

```bash
nix flake check
```

---

## 5.3 Seguridad declarativa: sudo granular

**El problema con `wheelNeedsPassword = false`:** deshabilitar password para todo el grupo wheel es cómodo pero viola el principio de least privilege. Si un proceso malicioso corre como tu usuario, tiene sudo sin fricción.

**La solución en tu config (`hosts/victus/`):**

```nix
security.sudo = {
  wheelNeedsPassword = true;   # default seguro restaurado

  extraRules = [
    {
      users = [ "rolando" ];
      commands = [
        # NOPASSWD quirúrgico: solo los comandos que realmente necesitan sudo sin password
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/btrbk";         options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-collect-garbage"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  extraConfig = "Defaults lecture=never";  # silencia el speech de sudo en primera ejecución
};
```

**Por qué este approach es mejor:**

| Opción | Comodidad | Seguridad | Cuándo usarla |
|---|---|---|---|
| `wheelNeedsPassword = false` | Maxima | Mínima | Jamás en producción; aceptable en lab sin red |
| `wheelNeedsPassword = true` (default) | Pide password siempre | Buena | Setup básico seguro |
| `extraRules` NOPASSWD granular | Pide solo cuando no está en la lista | Muy buena | Tu setup actual |

La clave es que `nixos-rebuild`, `btrbk` y `nix-collect-garbage` son las tres operaciones que corrés frecuentemente y donde el password interrumpe el flujo. Todo lo demás sigue pidiendo autenticación.

---

## 5.4 Entornos reproducibles por proyecto: direnv + devShells

**El problema:** tenés proyectos con deps distintas. `scraper-pedco` necesita Go. `nix-config` necesita los hooks de Nix. Si instalás todo globalmente en `home.packages`, contaminás el entorno del sistema y eventualmente hay conflictos de versiones.

**La solución:** cada proyecto declara sus deps en un `devShell` dentro de su `flake.nix`, y `direnv` lo activa/desactiva automáticamente al entrar/salir del directorio.

### Cómo funciona

1. `programs.direnv.enable = true` + `programs.direnv.nix-direnv.enable = true` en home-manager. `nix-direnv` extiende direnv con soporte nativo para flakes (cachea el devShell en el store, no lo re-evalúa cada vez).

2. Cada proyecto tiene un `.envrc`:

```bash
# ~/projects/nix-config/.envrc
use flake
```

3. La primera vez que entrás al directorio, direnv pide permiso:

```bash
cd ~/projects/nix-config
# direnv: error .envrc is blocked. Run `direnv allow` to approve.
direnv allow
```

4. Desde ese momento, al entrar el directorio, las deps del `devShell` aparecen en el PATH. Al salir, desaparecen. Sin tocar el sistema global.

### Ejemplo concreto

```bash
cd ~/projects/nix-config
# direnv activa el devShell → nixfmt, statix, deadnix en PATH

which nixfmt
# /nix/store/xxx-nixfmt-xxx/bin/nixfmt   ← viene del devShell

cd ~
which nixfmt
# nixfmt not found   ← desapareció al salir
```

### Comandos útiles de direnv

```bash
direnv allow          # habilitar .envrc del directorio actual (primera vez o tras editar)
direnv reload         # forzar re-evaluación del .envrc
direnv deny           # revocar permiso
direnv status         # ver si el .envrc está activo y qué exporta
```

---

## 5.5 Secretos declarativos: sops-nix

**El problema:** un token no puede ir en git en claro, pero tampoco puede quedar solo en tu disco — el día que reinstalás, el servicio que lo necesita queda roto y no te acordás de dónde salía. El Nix store además es **world-readable**, así que meter un secreto en una derivación es peor que no cifrarlo.

**La solución: cifrarlo con [sops](https://github.com/getsops/sops) y descifrarlo en runtime**, fuera del store.

### Cómo funciona la cadena

```
~/.ssh/id_ed25519  ──ssh-to-age──►  identidad age  ──►  descifra secrets/*.yaml
                                                          │
                                          sops-nix.service (al activar HM)
                                                          │
                                                          ▼
                                    ~/.config/sops-nix/secrets/rendered/pedco.env
                                                          │
                                              EnvironmentFile del unit
```

**La decisión de diseño que importa:** la identidad age se **deriva de la clave SSH** en vez de generar una nueva. Así no hay una segunda clave que respaldar — en una máquina nueva copiás la SSH (que ibas a copiar igual) y los secretos se descifran solos.

```nix
# .sops.yaml — el recipient es público, va en git tranquilo
keys:
  - &rolando age1chjr3jrprx3l...
creation_rules:
  - path_regex: secrets/.*
    key_groups: [ { age: [ *rolando ] } ]
```

```nix
# home/rolando.nix
imports = [ inputs.sops-nix.homeManagerModules.sops ];

sops = {
  age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  secrets.TG_TOKEN.sopsFile = ../secrets/pedco.yaml;
  # los units piden un EnvironmentFile, no secretos sueltos:
  templates."pedco.env".content = ''
    TG_TOKEN=${config.sops.placeholder.TG_TOKEN}
  '';
};
```

### Los dos gotchas que cuestan tiempo

**1. Ordenar contra `sops-nix.service`.** El template se renderiza en la activación. Un servicio que arranca en el login sin declarar ese orden lee un `EnvironmentFile` que todavía no existe y falla:

```nix
Unit.After = [ "sops-nix.service" ];
Unit.Wants = [ "sops-nix.service" ];
```

**2. `creation_rules` matchea la ruta del archivo de ENTRADA.** Cifrar un archivo que vive fuera de `secrets/` da `error loading config: no matching creation rules found`, aunque redirijas la salida ahí. Se resuelve con `--filename-override`:

```bash
sops -e --input-type dotenv --output-type yaml \
  --filename-override secrets/pedco.yaml  ~/proyecto/.env  > secrets/pedco.yaml
```

**Para descifrar a mano (`sops -d`, editar, este `diff`) el CLI necesita `SOPS_AGE_KEY`**: él no deriva la clave de la SSH, solo sops-nix lo hace. Ver [runbooks/sops-secretos](../runbooks/sops-secretos.md#paso-0--la-variable-que-el-cli-necesita-siempre).

**Verificá el round-trip antes de borrar el original.** No alcanza con "cifró sin error": comparar hashes valor por valor. El formato `dotenv` puede descartar líneas que no sean `K=V`:

```bash
diff <(sops -d --output-type dotenv secrets/pedco.yaml) ~/proyecto/.env
```

---

## 5.6 Disco declarativo: disko

**El problema:** el `hardware.nix` que genera `nixos-generate-config` tiene los **UUID de esa máquina**. Es lo único de tu flake que no es portable: en otra PC no bootea. Y el particionado (tamaños, LUKS, subvolúmenes) queda como conocimiento tácito que no vas a recordar en dos años.

**Esta es la respuesta a "¿hago un script de instalación tipo Arch?": no.** En Arch escribís un script porque el estado del sistema es imperativo. En NixOS la config **ya es** el instalador — salvo el disco. [`disko`](https://github.com/nix-community/disko) cierra ese último hueco.

```nix
# hosts/victus/disk.nix — GPT + LUKS + btrfs con subvolúmenes
disko.devices.disk.main = {
  device = "/dev/nvme0n1";        # el ÚNICO valor atado al disco
  content.type = "gpt";
  content.partitions = {
    ESP = { label = "ESP"; size = "1G"; type = "EF00"; content = { ... }; };
    primary = {
      label = "primary"; size = "100%";
      content = {
        type = "luks"; name = "cryptroot";
        content.type = "btrfs";
        content.subvolumes."@".mountpoint = "/";
        # …@home, @nix, @log, @snapshots
      };
    };
  };
};
```

Con eso, `hardware.nix` queda reducido a módulos de kernel del initrd y microcódigo — **sin un solo UUID**, portable tal cual.

### El detalle que hace la diferencia: `label`

disko referencia particiones por `/dev/disk/by-partlabel/<label>`, y el label por defecto es `gpt-<disco>-<partición>` (ej. `gpt-main-ESP`). **Si adoptás disko en un disco que ya existe, esos paths no existen y no bootea.**

Fijar el label a mano resuelve las dos direcciones:

```nix
ESP = { label = "ESP"; ... };   # coincide con la etiqueta que el disco YA tiene
```

En una instalación nueva disko la crea con ese nombre; en la máquina actual ya está. Verificá con `lsblk -o NAME,PARTLABEL`.

### Adoptarlo en una máquina que ya está andando

`disko.enableConfig` (default `true`) hace que disko **genere los `fileSystems`**, lo que choca con los que ya declara tu `hardware.nix`. Dos caminos:

| `enableConfig` | Qué hace | Cuándo |
|---|---|---|
| `false` | solo formatea; `hardware.nix` sigue mandando | querés riesgo cero y solo versionar el layout |
| `true` | genera `fileSystems`; se los sacás a `hardware.nix` | querés "clonar e instalar" de verdad |

**Con `true`, verificá antes de switchear.** Es config de arranque: se diffean los `fileSystems` evaluados contra los del sistema corriendo, sin construir ni activar.

```bash
# baseline ANTES de tocar nada
nix eval --json '.#nixosConfigurations.HOST.config.fileSystems' > /tmp/fs-antes.json
# …hacer los cambios, y después comparar device/fsType/options por punto de montaje
```

Al adoptarlo acá dio **6 de 7 idénticos**; la única diferencia fue `/boot` pasando de `by-uuid/AA36-39F6` a `by-partlabel/ESP`, y `readlink -f` confirmó que ambos resuelven a `/dev/nvme0n1p1`. Recién ahí se commitea.

> **El switch no es la prueba, el reboot sí.** Al switchear los montajes ya están montados, así que un error no se manifiesta hasta reiniciar. La red es el menú de systemd-boot con la generación anterior.

### Lo que disko no puede cubrir

Los subvolúmenes anidados dentro de `@home` (ej. `~/.cache`, `~/.local/share/Steam/steamapps`) **no van en `disk.nix`**: se crean al formatear, cuando el home del usuario todavía no existe. Van como paso post-instalación.

```bash
# CUIDADO: destroy FORMATEA el disco. Solo en instalación nueva.
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake .#HOST
```

---

## 6. Debugging — leer errores como un nativo

### El error: linea por linea

```
error: attribute 'satti' missing
       at /home/rolando/projects/nix-config/home/rolando.nix:128:5:
          127|     slurp
          128|     satti
             |     ^
          129|     wl-clipboard
       Did you mean satty?
```

**Cómo se lee:**
- `attribute 'satti' missing` → un paquete u opción con ese nombre no existe.
- La línea y columna te dicen dónde lo escribiste mal.
- A veces sugiere — `Did you mean satty?` — confiá pero verificá en search.nixos.org.

### Top errores y qué significan

| Mensaje | Causa común | Fix típico |
|---|---|---|
| `attribute 'X' missing` | Typo en paquete u opción | Buscar el nombre real en search.nixos.org |
| `error: function called with unexpected argument 'X'` | La opción cambió de nombre entre versiones de nixpkgs | Buscar el nuevo nombre en search.nixos.org o changelog |
| `error: infinite recursion encountered` | Referencia circular en `let` o `inherit` | Romper el ciclo, usar `lib.mkForce` o reestructurar |
| `error: assertion '...' failed` | Combinación inválida (ej: dos display managers a la vez) | Leer la assertion para entender el conflicto |
| `hash mismatch in fixed-output derivation` | Estás bajando algo y el hash declarado no coincide con el contenido | Copiar el hash real que te muestra el error |
| `collision between '/nix/store/A-prog' and '/nix/store/B-prog'` | Dos paquetes proveen el mismo binario | Usar `lib.hiPrio` en uno, o sacar uno |
| `error: builder for X failed with exit code 1` | Build de un paquete falló | Mirar el log que sigue — típicamente upstream tiene un bug en esa versión |

### `--show-trace` siempre que el error sea opaco

```bash
sudo nixos-rebuild switch --flake ~/projects/nix-config --show-trace
```

Te da el stack completo de evaluación. Largo pero a veces es la única forma de ver de dónde viene un error.

### Probar evaluaciones puntuales

```bash
nix-instantiate --eval -E 'with import <nixpkgs> {}; lib.versions.major pkgs.k3s.version'
# "1"
```

Útil para chequear "¿qué versión va a usar?", "¿esta función existe?", etc.

### Cómo encontrar opciones obscuras

```bash
# Ver TODAS las opciones de un namespace
man configuration.nix | grep -A 2 "services.k3s\."

# Ver el default y descripción de UNA opción
nixos-option services.k3s.enable
# (requiere estar dentro del sistema, no funciona con flakes puros — usar search.nixos.org)
```

---

## 7. Rollback y generaciones

Cada `switch` crea una **generación** numerada. Podés volver a cualquiera.

```bash
# Ver generaciones disponibles
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Rollback a la inmediatamente anterior
sudo nixos-rebuild switch --rollback

# Rollback a una específica
sudo /nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

En el menú de **systemd-boot** también aparecen todas las generaciones al boot — útil si rompiste algo que impide login.

**Limpiar generaciones viejas** (ocupan disco):

```bash
nh clean all --keep 5       # mantiene las últimas 5
# o
sudo nix-collect-garbage --delete-older-than 14d
```

---

## 8. Cheatsheet de referencia rápida

```nix
# CLI tool user
home.packages = with pkgs; [ kubectl k9s bat ];

# CLI tool sistema (admin/root)
environment.systemPackages = with pkgs; [ git vim ];

# Programa con módulo
programs.firefox.enable = true;
programs.zsh.enable = true;

# Servicio sistema (daemon)
services.openssh.enable = true;
services.k3s = {
  enable = true;
  role = "server";
};

# Servicio user (systemd --user)
systemd.user.services.miDaemon = {
  description = "...";
  wantedBy = [ "graphical-session.target" ];
  serviceConfig.ExecStart = "...";
};

# Hardware
hardware.bluetooth.enable = true;

# Firewall
networking.firewall.allowedTCPPorts = [ 22 80 443 6443 ];

# Fonts
fonts.packages = with pkgs; [ jetbrains-mono ];

# Dotfile mutable (home-manager)
home.file.".config/foo".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dotfiles/foo";
```

```bash
# Buscar
nh search <nombre>
nix search nixpkgs <nombre>

# Aplicar (flujo moderno con aliases)
rebuild-test                              # valida sin persistir
rebuild                                   # aplica + nueva generación
nixos-version --configuration-revision    # qué commit es esta generación

# Aplicar (raw, sin aliases)
nh os switch ~/projects/nix-config       # con UX bonita y diff
NH_NOM=1 nh os switch ~/projects/nix-config  # mismo pero con árbol de build visual

# Validar sin aplicar
nh os build ~/projects/nix-config        # compila en ./result, no activa
nix flake check                          # valida hooks y evaluación del flake

# Debug
sudo nixos-rebuild switch --flake ~/projects/nix-config --show-trace

# Rollback
sudo nixos-rebuild switch --rollback

# Limpiar
nh clean all --keep 5
```

---

## 9. Cómo abordar "instalá X" cuando no sabés por dónde empezar

1. **Buscar el nombre real:** `nh search X` o search.nixos.org/packages.
2. **¿Tiene módulo?** Buscar en search.nixos.org/options por `programs.X`, `services.X`, `hardware.X`. Si aparece → usar el módulo.
3. **Decidir scope:** user-only → `home/`; system-wide o daemon → `modules/` o `hosts/`.
4. **Leer las opciones del módulo:** mirá `enable`, `package`, los principales (no todas, hay decenas). Default = lo que pasa sin tocar nada.
5. **Editar declarativamente:** agregar el bloque mínimo. NO copiar 30 líneas que no entendés.
6. **`nh os switch` o `dry-build`:** validar antes de aplicar.
7. **Verificar:** si era un servicio, `systemctl status X`. Si era un binario, ejecutarlo a ver si arranca.
8. **Si falla:** leer el error siguiendo la sección 6. `--show-trace` si es opaco. Buscar el mensaje exacto en Google + "nixos" si no es obvio.

---

## 10. Pendientes arquitectónicos — AMBOS RESUELTOS (histórico + lecciones)

### B3 — `pedco-bot` como flake input ✅ (hecho 2026-06-20)

`scraper-pedco` expone su propio `flake.nix`; en `nix-config` es un input con
`follows = "nixpkgs"` (evita duplicar nixpkgs en el lock). El daemon + el timer de
avisos (`Persistent=true` = catch-up tras suspend/apagado) se declaran en
`home/rolando.nix` con el binario pineado al store. Actualizar el bot:
`nix flake update pedco-bot && rebuild`.
**Desvío del plan original:** los secretos NO migraron a sops-nix — quedaron vía
`EnvironmentFile=` apuntando fuera del repo, que ya era suficiente (no había
secreto en el store ni en git; agregar sops habría sido complejidad sin consumidor).

### C3 — specialisation "battery" ✅ hecha 2026-07-20 → ❌ **ELIMINADA 2026-07-29**

**Por qué se eliminó, con datos.** Su contenido completo eran dos `mkForce false`
(k3s + scx) — y `systemctl stop` logra exactamente lo mismo. A cambio costaba:

- un **build extra en cada rebuild** (`nixos-system-victus-battery-….drv`),
- una **entrada de boot por generación** (45 acumuladas en el menú),
- y bootear ahí por accidente —systemd-boot recuerda la última entrada— dejaba el
  botón "modo juego" de waybar **sin unit que togglear**: `k3s.service` no existe en
  esa variante y `is-active` devuelve `inactive` igual que si estuviera parado.

En disco era barata (solo **12 paths exclusivos**, comparte casi todo el closure), así
que el argumento no fue el espacio: fue el build, el ruido en el menú y que su función
ya la cubría un botón. Además el ahorro de apagar scx a batería **nunca se midió** (era
la fase 2, siempre pendiente) — difícil justificar infraestructura por un beneficio no
medido.

Hoy: los aliases `battery-on/off` hacen `systemctl stop|start` de ambos servicios, y el
botón de waybar cubre los dos.

**Lo que sigue siendo cierto sobre specialisations en general** (vale aprenderlo, la
feature es útil en otros casos): heredan toda la config y solo declarás el delta; el
cambio es **en caliente sin reboot** porque el script de activación para/arranca
exactamente las units que difieren; y **no crean generaciones** —viven dentro del mismo
toplevel—, así que togglear no toca el profile. Sirven cuando el delta es grande o
necesitás elegirlo **al bootear**; para "parar dos daemons", son desproporcionadas.

<details><summary>Implementación histórica (referencia)</summary>

Estaba en `modules/battery.nix` (no TLP como imaginaba la nota original — ppd ya cubre
la capa hardware):

```nix
specialisation.battery.configuration = {
  system.nixos.tags = [ "battery" ];
  services.k3s.enable = lib.mkForce false;   # mkForce: gana sobre el enable=true
  services.scx.enable = lib.mkForce false;   # de k3s.nix / gaming.nix
};
```

**Tres lecciones que la nota original no sabía:**
1. **El cambio de perfil es en caliente, sin reboot** (la nota decía "solo
   reiniciando" — falso): el script de activación de la variante para/arranca
   exactamente las units del delta. Aliases: `battery-on` / `battery-off`.
2. **No crea generaciones**: la specialisation vive DENTRO del mismo toplevel;
   activarla no toca el profile. Verificado empíricamente (toggles repetidos,
   misma gen). Solo los cambios reales de config crean generaciones.
3. La vía sin fricción es el script de activación directo
   (`/run/current-system/specialisation/battery/bin/switch-to-configuration switch`,
   con NOPASSWD quirúrgico solo para el arg `switch`) — `nixos-rebuild
   --specialisation` funciona igual pero re-evalúa el flake entero (~10-30s al pedo).

**Fase 2 con gatillo:** medir a batería (`upower -i ... | grep energy-rate`, 5 min
por perfil) y sumar ananicy/gamescope al mkForce SOLO si el ahorro de k3s+scx no alcanza.

</details>

**El pendiente de medir sigue vivo**, ahora sin specialisation: comparar `energy-rate`
con k3s+scx corriendo vs parados (`battery-on`). Si el delta es despreciable, hasta los
aliases sobran.

---

## 11. Recursos canónicos (cuando esta guía no alcance)

- **NixOS Manual** → https://nixos.org/manual/nixos/stable/
- **Nixpkgs Manual** (para overrides y patterns avanzados) → https://nixos.org/manual/nixpkgs/stable/
- **Home-Manager options** → https://nix-community.github.io/home-manager/options.xhtml
- **search.nixos.org** — todo lo de búsqueda
- **NixOS Discourse** → https://discourse.nixos.org/ — el foro, MUY útil para errores raros
- **noogle.dev** — buscador de funciones de la stdlib de Nix
- **Reddit r/NixOS** — comunidad activa, buenas discusiones de patrones
- **pre-commit-hooks.nix** → https://github.com/cachix/pre-commit-hooks.nix
- **nix-direnv** → https://github.com/nix-community/nix-direnv

**Para Flakes específicamente** (que es lo que vos usás):
- https://nixos.wiki/wiki/Flakes
- "Zero to Nix" (zero-to-nix.com) — guía moderna 100% flakes

---

*Última actualización: 2026-06-04. Este doc vive en `~/Documentos/Guia-NixOS-Practica.md` — editalo libremente a medida que descubrís patrones nuevos.*
