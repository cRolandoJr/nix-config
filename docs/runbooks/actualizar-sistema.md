# Actualizar el sistema — flake, lock, dry-run, pin

Referencia de comandos: [nix-cheatsheet §3](../guias/nix-cheatsheet.md#3-actualizar-inputs-nixpkgs-home-manager-etc).
Si algo sale mal: [rebuild-falla](rebuild-falla.md) y [rollback](rollback.md).

## Los dos archivos, y por qué son dos

| | Qué dice | Ejemplo |
|---|---|---|
| `flake.nix` | **qué querés**: una rama | `nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"` |
| `flake.lock` | **qué tenés**: el commit exacto de cada input | `nixpkgs → 6774f7b…` (22-sep) |

Una rama se mueve sola; un commit no. El lock es lo que hace que un `rebuild` de hoy y
uno dentro de un mes den **el mismo sistema**, hasta que decidís actualizar. Actualizar
es solo esto: mover el lock a commits más nuevos.

Ver qué tenés hoy y de qué fecha:

```bash
cd ~/projects/nix-config
nix flake metadata
```

`follows` (en `flake.nix`): `inputs.nixpkgs.follows = "nixpkgs"` hace que home-manager,
sops-nix, etc. usen TU nixpkgs y no traigan el suyo. Sin eso habría varios nixpkgs en el
lock y en el disco.

## El procedimiento seguro

**1. Partir de un árbol limpio.** Así el update es un commit solo y se revierte limpio.

```bash
git status --short          # vacío
```

**2. Mover el lock, sin aplicar nada.**

```bash
update                              # todos los inputs
nix flake update nixpkgs            # o uno solo
git diff flake.lock                 # qué inputs se movieron
```

**3. Dry-run: construir sin activar y ver qué cambia.**

```bash
nh os build ~/projects/nix-config   # construye y muestra el diff de paquetes; NO activa
```

Mirar en el diff: `linux`, `mesa`, `hyprland`, `systemd`. Si alguno cambió, el paso 4 es
`boot`, no `switch`. Si el build falla acá, no rompiste nada: seguís en el sistema de
antes (ver [rebuild-falla §3](rebuild-falla.md#3-un-paquete-no-compila-después-de-update)).

`nh os switch --dry` hace lo mismo desde el comando de siempre. `nh os switch --ask`
construye, muestra el diff y **pregunta** antes de activar.

**4. Aplicar.**

| Cambió | Usar | Por qué |
|---|---|---|
| kernel, Mesa, GPU, Hyprland, systemd | `rebuild-boot` + `reboot` | un `switch` en caliente puede tirarte la sesión, y con un kernel nuevo rompe `scx` |
| el resto | `rebuild` | |

**5. Verificar** ([rebuild-falla §0](rebuild-falla.md#0-cambió-el-sistema-de-verdad)) y
**commitear el lock solo**:

```bash
git add flake.lock && git commit -m "update: flake inputs $(date +%F)"
```

**6. Si algo se rompe**: `git revert` de ese commit + `rebuild` vuelve al lock anterior.
El rollback de generación ([rollback](rollback.md)) arregla el sistema en el momento,
pero no el repo.

## Pinear: quedarse en un commit viejo a propósito

Cuando un update rompe un paquete y no podés esperar. Pasó el 27-jul-2026: `lact` no
compilaba en unstable y se pineó nixpkgs al 23-jul.

**1. Averiguar el commit bueno**: el de un lock anterior que funcionaba.

```bash
git log --oneline -- flake.lock                 # elegir el commit del lock bueno
c=<commit>
git show "${c}:flake.lock" | jq -r '.nodes.nixpkgs.locked | "\(.rev) \(.lastModified | todate)"'
```

En zsh van las llaves: `"$c:flake.lock"` falla, porque zsh lee `:f` como modificador
de la variable.

**2. Pinear en `flake.nix`, con motivo y gatillo en el comentario**:

```nix
# PIN (27-jul-2026): lact no compila con libdisplay-info 0.4 (unstable del 25-jul).
# Levantar cuando `nix build github:NixOS/nixpkgs/nixos-unstable#lact` pase.
nixpkgs.url = "github:NixOS/nixpkgs/e220185ff6e66544862579018f33012372bb708f";
```

Un pin sin comentario es una trampa: **`update` no lo mueve y no avisa**, y meses
después nadie sabe por qué el sistema no trae nada nuevo.

**3. Levantarlo** cuando se cumpla el gatillo: volver a `nixos-unstable` y seguir el
procedimiento seguro desde el paso 2. Probar el gatillo sin tocar el repo:

```bash
nix build github:NixOS/nixpkgs/nixos-unstable#<paquete>   # si baja del caché, Hydra ya lo arregló
```

### Pin más fino: un solo paquete

Si lo roto es un paquete y no todo nixpkgs, mejor pinear solo ese
(`pkg.override { ... }` o un overlay): el resto del sistema se sigue actualizando. Ver
[nixos-practica §4](../guias/nixos-practica.md#4-patrones-más-avanzados-te-van-a-aparecer-eventualmente).

## Inputs propios (pedco-bot)

`pedco-bot` es un repo tuyo como input. Para traer un cambio: push al repo del bot, y acá
`nix flake update pedco-bot` + `rebuild`. No hace falta tocar el resto.
