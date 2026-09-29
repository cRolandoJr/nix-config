# Nix / NixOS — cheatsheet práctico

Tu setup: flake en `~/projects/nix-config/`, host `victus`, user `rolando`.
Todos los aliases y funciones viven en `~/projects/nix-config/home/rolando.nix`
(sección `programs.zsh`). Inventario completo y qué hace cada uno: **sección 0**.

---

## 0. Tus comandos propios (inventario completo · jul-2026)

### Sistema NixOS

| Comando | Qué hace realmente | Por qué existe |
|---|---|---|
| `rebuild` | `nh os switch` — eval + build + activa nueva generación | El apply diario. nh detecta el host por hostname. |
| `rebuild-test` | `nh os test` — build + activa **sin** entrada de boot | Probar un cambio reversible con reboot. Primer paso ante cambios riesgosos. |
| `rebuild-boot` | `nh os boot` — build + activa **solo al próximo boot** | Kernel/Mesa/GPU/stack gráfico: evita el logout del switch en caliente. |
| `update` | `cd nix-config && nix flake update` | Solo mueve `flake.lock`; la descarga real pasa en el rebuild. |
| `gc` | `nix-collect-garbage --delete-older-than 7d` system **y** user | Libera store sin perder el rollback reciente (mismo criterio que el gc semanal). |
| `nixos-version --configuration-revision` | Imprime el commit de git **de la generación booteada** | Puente git↔store. Reemplazó a `tag-gen` (28-jul-2026): esa función era manual y llegó a 9 tags sobre 144 gens. |

### Perfil de energía (jul-2026)

| Comando | Qué hace realmente | Por qué existe |
|---|---|---|
| `battery-on` | `systemctl stop` de **k3s + scx** + EPP `power-saver` + refresca waybar | Modo "me voy sin cargador". Sin generación nueva, sin reboot. |
| `battery-off` | `systemctl start` de los dos + EPP `balanced` + refresca waybar | La vuelta. NOPASSWD acotado, un unit por invocación. |

**La specialisation `battery` se ELIMINÓ el 29-jul-2026.** Su contenido eran dos
`mkForce false` (k3s + scx) que `systemctl stop` logra igual. Costaba un build extra
en cada rebuild y una entrada de boot por generación (45 acumuladas) — y bootear ahí
por accidente dejaba el botón modo juego sin unit que togglear. Los aliases hacen lo
mismo ahora, y el botón de waybar cubre los dos servicios.

**REMOVIDO 28-jul-2026:** el widget de perfil de energía de waybar, su script
`toggle-power-profile.sh` y el bind `SUPER+CTRL+P`. Razón: en este equipo
`power-profiles-daemon` **solo mueve el CPU** — no existe
`/sys/firmware/acpi/platform_profile` y ppd reporta `PlatformDriver: placeholder`,
así que nunca controló ventiladores ni TDP. Sus tres perfiles ya tenían dueño:
`performance` lo cubre `gamemoderun` por juego, y `power-saver`/`balanced` los
aliases de arriba. **El daemon queda** (los aliases dependen de `powerprofilesctl`),
y `hyprlock` sigue mostrando el perfil.

### Modo juego (botón de waybar, jul-2026)

| Comando | Qué hace | Nota |
|---|---|---|
| click en el 󰊴 de waybar | Para/arranca **k3s + scx** | k3s idle: **6.7% CPU y 539 MiB** (medido). scx_lavd gasta CPU para bajar latencia. Cyan = parados. |
| `waybar-gamemode.sh toggle` | Lo mismo desde CLI | Estado derivado de `systemctl`, no de un flag. Reemplazó a la specialisation `battery`. |

Queda un residual de ~197 MiB y 0.4% en containerd-shims huérfanos; existe
`k3s-killall.sh` para eso pero no vale la pena.

### Snapshots btrfs (btrbk)

| Comando | Qué hace | Nota |
|---|---|---|
| `snap` | Snapshot manual de `@home` ya | Antes de una operación riesgosa en $HOME. |
| `snap-ls` | Lista snapshots existentes | Los horarios corren solos (timer btrbk). |
| `snap-dry` | Simula sin crear | Verificar qué haría. |

### Utilitarios

| Comando | Qué hace | Nota |
|---|---|---|
| `ll` / `ls` / `tree` | `eza` con iconos (+`-la --git` en ll) | |
| `cat` | `bat` (syntax highlight) | `command cat` para el cat real. |
| `scrcpy` | scrcpy con mouse uhid, shortcut-mod lsuper, opengl | Flags anti-stutter Wayland; lsuper no choca con alt_shift_toggle. |
| `gs` `gd` `gco` `gcm` `gp` `gl` | git status/diff/checkout/commit -m/push/pull | |

### Sudo sin password (lista exacta — todo lo demás pide clave)

`nixos-rebuild` · `btrbk` · `nix-collect-garbage` ·
`systemctl stop|start k3s.service` · `systemctl stop|start scx.service`

Las cuatro de systemctl son del botón modo juego y de los aliases `battery-on/off`.
Las dos de `switch-to-configuration` se quitaron el 29-jul junto con la specialisation:
el privilegio se redujo. **sudoers exige match exacto del comando
completo cuando la regla especifica argumentos**, así que eso NO habilita systemctl
genérico — verificado: `sudo -n systemctl stop sshd.service` sigue pidiendo clave.

---

## 1. Rebuild del sistema

| Comando | Qué hace | Cuándo usarlo |
|---|---|---|
| `rebuild-test` (alias) | Eval + build + activa **sin** entrada de boot | Primer paso ante cambios riesgosos: un reboot vuelve a la generación anterior. |
| `rebuild` (alias) | Eval + build + **activa** como generación actual | Después de que `rebuild-test` pase OK. |
| `rebuild-boot` (alias) | Build + activa **solo al próximo boot** | Si tocaste kernel/initrd/bootloader y quieres aplicar en reinicio. |
| `nixos-version --configuration-revision` | Imprime el commit de la generación booteada | Cuando estás en una gen vieja y querés saber qué config es |
| `NH_NOM=1 rebuild` | Igual que `rebuild` pero con árbol de build visual | Cuando quieras ver qué se está compilando en tiempo real |
| `nh os rollback` | Vuelve a la generación anterior | Si una build se rompió. Detalle en [runbooks/rollback](../runbooks/rollback.md). |

**Flujo recomendado al tocar config:**
```bash
rebuild-test          # verifica que evalúa y compila
rebuild               # si OK, activa (crea nueva generación)
```

**Commitear ANTES de rebuildear:** `system.configurationRevision` embute
`self.rev` en la generación, y `self.rev` solo existe con el árbol limpio. Si
rebuildeás sucio, la generación queda marcada `<sha>-dirty` y perdés el puente
exacto al commit.

**`switch` vs `boot` (evitar logout):** `switch` reinicia en caliente los servicios que cambiaron. Si el cambio toca el stack gráfico (Mesa, dbus, wayland, Hyprland, kernel) → te tira la sesión (logout). `boot` deja la generación lista para el próximo arranque sin tocar la sesión actual.

| Cambio | Usar |
|---|---|
| Dotfile, paquete CLI | `rebuild` (switch) |
| `flake update`, cambio de canal, kernel/Mesa/GPU | `rebuild-boot` + `reboot` |

Síntoma del salto stable→unstable: 1er `switch` logout, 2do `switch` logout sin nueva gen, 3ro limpio. Se evita usando `rebuild-boot` + `reboot` desde el inicio para cambios grandes.

---

## 2. Generaciones (snapshots del sistema)

Cada `rebuild` crea una **generación**. Coexisten y puedes saltar entre ellas.

```bash
# Listar generaciones del sistema
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Listar generaciones de home-manager
nix-env --list-generations --profile /nix/var/nix/profiles/per-user/$USER/home-manager

# Cambiar a una generación específica (rollback granular)
sudo /nix/var/nix/profiles/system-NN-link/bin/switch-to-configuration switch

# Ver las generaciones al bootear: menú de systemd-boot (entradas "NixOS - Configuration N"
# ya sin entradas "battery": la specialisation se eliminó el 29-jul)
```

---

## 3. Actualizar inputs (nixpkgs, home-manager, etc.)

`flake.nix` declara qué quieres. `flake.lock` es el snapshot exacto. Las dos cosas viven separadas.

```bash
# Actualizar TODOS los inputs (rama → último commit)
nix flake update                         # tu alias: `update`

# Actualizar solo un input
nix flake update nixpkgs
nix flake update home-manager

# Ver qué tienes locked vs qué hay disponible
nix flake metadata ~/projects/nix-config

# Volver atrás un update no aplicado todavía
cd ~/projects/nix-config && git checkout flake.lock
```

**Regla**: `flake update` NO descarga paquetes. Solo modifica `flake.lock`. La descarga pasa en `rebuild`.

**Hábito sano**: después de `update`, hacer `rebuild` enseguida (en una sentada). No dejes el lock "flotando" — terminas con un rebuild gigante semanas después.

---

## 4. Garbage collection (liberar espacio)

Hay un gc automático semanal (`nix.gc` en `modules/base.nix`, borra lo más viejo que 7 días). Esta sección es para cuando hace falta más. Si el disco se llena: [runbooks/disco-lleno](../runbooks/disco-lleno.md).

```bash
# Cuánto pesa tu store
du -sh /nix/store
df -h /nix

# Qué generaciones puedes borrar (todas las viejas)
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# GC suave: borra solo lo que ningún profile referencia
nix-collect-garbage                       # user
sudo nix-collect-garbage                  # system

# GC duro: borra TODAS las generaciones viejas (deja solo la actual, sin rollback)
sudo nix-collect-garbage -d               # evitarlo: usar `gc` (7 días) o `+N` abajo

# Borrar generaciones más viejas que N días
sudo nix-collect-garbage --delete-older-than 30d

# Dejar solo las últimas N generaciones
sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

# Borrar generaciones específicas
sudo nix-env --delete-generations 1 2 3 --profile /nix/var/nix/profiles/system

# Optimizar store (deduplica archivos idénticos por hash)
nix-store --optimise
```

**Cuándo correr `gc` a mano**: casi nunca, el semanal ya corre. Si el gc libera poco, lo que retiene suele ser un `result` o un `.direnv` olvidado (ver el runbook). Después de un `-d` ya no hay rollback a generaciones viejas.

---

## 5. Buscar paquetes

```bash
# Buscar paquetes (online, sin instalar)
nix search nixpkgs firefox
nix search nixpkgs telegram

# Ver el flake actual del registry
nix registry list

# Inspeccionar un paquete sin instalarlo
nix shell nixpkgs#htop                    # entrada efímera; sale del shell y desaparece
nix run nixpkgs#cowsay -- "hola"          # corre directo sin entrar al shell

# Web: search.nixos.org (UI bonita para buscar)
# Web: home-manager-options.extranix.com (opciones home-manager)
```

---

## 6. Inspección del store

```bash
# Ver qué hay en una path
ls /nix/store/<hash>-paquete-version/

# Ver de dónde viene una path
nix-store --query --deriver /nix/store/<hash>-...

# Cosas que dependen de X (referrers)
nix-store --query --referrers /nix/store/<hash>-...

# Cosas que X depende (referencias)
nix-store --query --references /nix/store/<hash>-...

# Árbol completo
nix-store --query --tree /nix/store/<hash>-...

# Tamaño en disco de una path y todo lo que arrastra
nix path-info -rsh /nix/store/<hash>-...

# Los 20 paquetes más pesados de tu sistema actual
nix path-info -rsh /run/current-system | sort -hk2 | tail -20

# Cuál fue la última build del sistema
readlink -f /run/current-system
```

---

## 7. Debug de eval / build

```bash
# Eval verbose (ver qué archivos lee)
sudo nixos-rebuild dry-run --flake ~/projects/nix-config#victus --show-trace

# Eval con stack trace (errores raros de Nix)
nix flake show ~/projects/nix-config --show-trace

# Probar una expresión Nix sin instalar nada
nix eval --raw nixpkgs#hello.meta.description
nix eval ~/projects/nix-config#nixosConfigurations.victus.config.networking.hostName

# REPL para explorar nixpkgs
nix repl
# luego adentro:
#   :lf nixpkgs
#   legacyPackages.x86_64-linux.firefox.meta
```

---

## 8. Diff entre generaciones

```bash
# Ver qué cambió entre la generación actual y la anterior (paquetes added/removed/upgraded)
nix store diff-closures /nix/var/nix/profiles/system-{N,M}-link

# Mismo pero contra el rebuild en curso (antes de activar)
nix store diff-closures /run/current-system ./result
```

Útil cuando dices "qué carajos cambió" después de un update.

---

## 9. Profile management (paquetes user-level fuera de home-manager)

Para apps efímeras sin tocar el flake:

```bash
nix profile install nixpkgs#htop          # instala en profile user
nix profile list                          # listar
nix profile remove htop                   # desinstalar
nix profile upgrade '.*'                  # actualizar todos
```

**Tu caso**: como usas home-manager declarativo, NO uses esto para nada permanente. Solo para probar algo rápido.

---

## 10. Channels (legacy, NO uses si vives en flakes)

Tu sistema es flake-only. Los `nix-channel` son el sistema viejo. Si ves un comando con `nix-channel`, `nix-env -iA nixos.foo`, etc., es del mundo pre-flakes. Ignóralo en tu setup.

---

## 11. Troubleshooting clásico

| Síntoma | Diagnóstico |
|---|---|
| "Git tree is dirty" warning en rebuild | Tienes cambios sin commitear en `~/projects/nix-config`. Inofensivo, pero el hash del flake es no-determinista hasta que commits. |
| Rebuild dice "X is broken" | Paquete marcado como broken en nixpkgs. Override con `allowBroken = true;` en `nixpkgs.config` o usa otra versión. |
| Rebuild dice "infinite recursion" | Importaste el mismo módulo dos veces, o tienes una `imports` cíclica. |
| Cambié un dotfile y home-manager no lo aplica | Si está en `xdg.configFile."x".source = mkOutOfStoreSymlink ...` el archivo del dotfile es el "source of truth" — editar ahí basta, no hace falta rebuild. Para cambios en `home/rolando.nix` sí hay que `rebuild`. |
| "file 'nixpkgs' was not found in the Nix search path" | `NIX_PATH` no apunta a nada. En flakes no se usa; el flake.lock pinea todo. Si un comando viejo lo pide: `export NIX_PATH=nixpkgs=flake:nixpkgs`. |
| `error: hash mismatch` en una build | El hash declarado de un fetch no coincide con lo descargado. Si es tu paquete custom (`pkgs/*.nix`), actualiza el `hash =`. Si es de nixpkgs, problema del upstream. |
| Sesión gráfica no recoge env var nueva tras rebuild | home.sessionVariables se aplican al **iniciar la sesión**. Logout/login para que se carguen. O workaround: `systemctl --user import-environment FOO`. |
| "path does not exist" con un archivo .nix que SÍ existe | **Los flakes solo ven archivos trackeados por git.** Archivo nuevo → `git add` (con stagear basta) antes del rebuild. Mordió el 20-jul con battery.nix. |
| ¿`battery-on/off` crea generaciones? | NO — son `systemctl stop/start`, no tocan el profile. Solo cambios reales de config crean gens. |

---

## 12. Comandos esenciales que vale la pena memorizar

```bash
rebuild-test                              # validar cambios
rebuild                                   # aplicar cambios (commitear ANTES: ver §1)
nixos-version --configuration-revision    # qué commit es la gen actual
battery-on / battery-off                  # para/arranca k3s+scx + EPP
update && rebuild-test                    # actualizar inputs y validar
sudo nixos-rebuild switch --rollback      # deshacer
nix-collect-garbage -d                    # limpiar (sin rollback posible después)
nix path-info -rsh /run/current-system | sort -hk2 | tail -10   # ver qué pesa
git -C ~/projects/nix-config diff         # qué editaste
nix flake check                           # validar flake + correr pre-commit hooks
```

---

## 13. Validación y calidad del flake

```bash
# Validar el flake completo (evaluación + hooks)
nix flake check

# Re-instalar el hook de pre-commit tras cambiar su config en flake.nix
nix develop --command true

# Correr los hooks manualmente sobre todos los archivos
# (equivalente a lo que hace pre-commit en cada commit)
nix flake check --no-build

# Ver qué hooks hay instalados
cat ~/projects/nix-config/.git/hooks/pre-commit
```

Hooks activos en tu flake: `nixfmt` (formato RFC 166), `statix` (anti-patrones), `deadnix` (bindings muertos).

---

## 14. DevShell lifecycle (direnv + nix-direnv)

```bash
# Primera vez en un proyecto con .envrc
direnv allow                   # autoriza el .envrc — solo hace falta una vez

# Si cambiás el flake.nix del proyecto (nuevas deps)
direnv reload                  # re-evalúa el devShell

# Ver si el entorno está activo y qué exporta
direnv status

# Entrar manualmente al devShell sin direnv
nix develop ~/projects/nix-config

# Regenerar hooks sin entrar interactivamente (útil en CI)
nix develop ~/projects/nix-config --command true
```

**Regla:** si `which nixfmt` dentro de `~/projects/nix-config/` no muestra nada, el devShell no está activo. Corré `direnv allow` o `nix develop`.

---

## 15. Inspección de profiles y generaciones

```bash
# Generation actual del sistema
readlink /nix/var/nix/profiles/system
# → /nix/store/xxx-nixos-system-xxx

# Número de generación actual
find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' | grep -oE '[0-9]+' | sort -n | tail -1
# (ojo: `ls` está aliasado a eza y rompe el parseo en scripts — usar find)

# Qué commit de git es ESTA generación
nixos-version --configuration-revision

# Profile del sistema en uso ahora mismo
readlink -f /run/current-system

# Ver todos los paths que forman el sistema actual (closure completa)
nix-store --query --requisites /run/current-system | wc -l

# Los 20 paquetes más pesados del sistema actual
nix path-info -rsh /run/current-system | sort -hk2 | tail -20

# Diff entre dos generaciones específicas
nix store diff-closures /nix/var/nix/profiles/system-{90,91}-link
```

---

## 16. Investigación (nix-tree, why-depends)

```bash
# Árbol visual de dependencias de un paquete (TUI interactiva)
nix-tree nixpkgs#firefox

# Por qué X depende de Y (útil para "quién mete openssl en mi closure")
nix why-depends /nix/store/<hash>-A /nix/store/<hash>-B

# Ver closure de la generación actual del sistema
nix-tree /run/current-system

# Qué paquetes cambiarían si actualizo nixpkgs (sin aplicar)
nh os build ~/projects/nix-config && nix store diff-closures /run/current-system ./result
```

---

## 17. LSP y nvim (gotchas del stack actual)

```bash
# nvim 0.12.x: :LspInfo y :LspRestart no existen más
# Reemplazos:
:checkhealth vim.lsp                          # diagnóstico del LSP
:lua vim.print(vim.lsp.get_clients())         # clientes activos y sus caps
:lua vim.lsp.stop_client(vim.lsp.get_clients()) # equivalente a "restart" (detener)
# y luego abrir el buffer de nuevo para reconectar
```

El binario real de neovim en NixOS es `nvim`, no `neovim`. Si `EDITOR=neovim` estaba seteado, los comandos que lo invocan (git, sudoedit) fallaban silenciosamente. El correcto es `EDITOR=nvim`.

---

## 18. Secretos con sops-nix (jul-2026)

La identidad age se **deriva de `~/.ssh/id_ed25519`**, así que no hay clave extra que
respaldar: en una máquina nueva, con esa SSH los secretos se descifran solos.

```bash
# Editar un secreto (abre $EDITOR con el contenido descifrado; re-cifra al guardar)
cd ~/projects/nix-config && sops secrets/pedco.yaml

# Ver el contenido descifrado sin editar
sops -d secrets/pedco.yaml
sops -d --output-type dotenv secrets/pedco.yaml     # como K=V

# Cifrar un archivo nuevo. --filename-override es OBLIGATORIO si la entrada
# vive fuera de secrets/: creation_rules matchea la ruta de ENTRADA.
sops -e --input-type dotenv --output-type yaml \
  --filename-override secrets/nuevo.yaml  ~/proyecto/.env  > secrets/nuevo.yaml

# Obtener el recipient age de una clave SSH (para .sops.yaml)
ssh-to-age < ~/.ssh/id_ed25519.pub

# Agregar una máquina/clave: editar .sops.yaml y después
sops updatekeys secrets/pedco.yaml

# Verificar el round-trip antes de confiar (el formato dotenv descarta no-K=V)
diff <(sops -d --output-type dotenv secrets/pedco.yaml) ~/proyecto/.env

# Dónde queda el archivo descifrado en runtime (NO está en el store)
ls ~/.config/sops-nix/secrets/rendered/
systemctl --user status sops-nix.service    # el unit que lo renderiza
```

**Gotcha de orden:** un servicio que use el secreto tiene que declarar
`After`/`Wants` de `sops-nix.service`, o arranca antes de que el archivo exista.

---

## 19. Disco declarativo con disko (jul-2026)

El layout vive en `hosts/victus/disk.nix`. **`hardware.nix` ya no tiene UUIDs.**

```bash
# ⚠️  destroy FORMATEA EL DISCO. Solo en instalación nueva, nunca acá.
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake .#victus

# Ver los partlabels reales (disko referencia by-partlabel)
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,MOUNTPOINT /dev/nvme0n1

# Verificar que los fileSystems generados coinciden con los actuales
# (hacerlo ANTES de switchear un cambio de disko: es config de arranque)
nix eval --json '.#nixosConfigurations.victus.config.fileSystems'

# Confirmar que un path by-partlabel resuelve al device esperado
readlink -f /dev/disk/by-partlabel/ESP        # → /dev/nvme0n1p1

# El fstab que bootearía, sin activar nada
nixos-rebuild build --flake .#victus && grep -v '^#' result/etc/fstab
```

**Post-instalación (disko no puede hacerlo):** los subvolúmenes anidados se crean
cuando ya existe el home del usuario.

```bash
btrfs subvolume create ~/.cache
btrfs subvolume create ~/.local/share/Steam/steamapps
```

---

## 20. Recursos

- **Wiki oficial**: https://wiki.nixos.org/
- **Buscar paquetes**: https://search.nixos.org/packages
- **Opciones NixOS**: https://search.nixos.org/options
- **Opciones home-manager**: https://home-manager-options.extranix.com/
- **Manual NixOS**: https://nixos.org/manual/nixos/stable/
- **Nix Pills** (entender Nix profundo): https://nixos.org/guides/nix-pills/
- **pre-commit-hooks.nix**: https://github.com/cachix/pre-commit-hooks.nix
- **nix-direnv**: https://github.com/nix-community/nix-direnv
