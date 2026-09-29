# Yazi — Guía Completa de Productividad

> Yazi es un file manager TUI escrito en Rust. La idea central: navegas como en vim (hjkl),
> operas archivos con teclas de una letra, y componés acciones en lugar de memorizar menús.

---

## Navegacion

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `h` | Directorio padre | Sube un nivel (salir de carpeta) |
| `j` / `k` | Abajo / Arriba | Mover cursor |
| `l` / `Enter` | Entrar / Abrir | Entra en carpeta o abre archivo |
| `gg` | Ir al primero | Primer elemento de la lista |
| `G` | Ir al ultimo | Ultimo elemento de la lista |
| `Ctrl+u` | Scroll up medio | Sube media pantalla |
| `Ctrl+d` | Scroll down medio | Baja media pantalla |
| `Ctrl+f` | Scroll full down | Baja pagina completa |
| `Ctrl+b` | Scroll full up | Sube pagina completa |
| `~` | Ir a home | Salta a `~` directamente |
| `/` | Buscar (incremental) | Filtra por nombre en directorio actual |
| `n` / `N` | Siguiente / Anterior match | Navegar resultados de `/` |

---

## Seleccion multiple

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `Space` | Toggle seleccion | Marca/desmarca el item y baja al siguiente |
| `v` | Modo visual | Seleccion de rango (combina con j/k) |
| `V` | Seleccion visual inversa | Invierte lo seleccionado |
| `Ctrl+a` | Seleccionar todo | Marca todos en el directorio |
| `Ctrl+r` | Invertir seleccion | Los marcados quedan desmarcados y viceversa |
| `Esc` | Limpiar seleccion | Sale del modo visual o limpia marcas |

**Patron util**: `Ctrl+a` luego `Space` en items que NO queres → rapido para operar sobre "casi todo".

---

## Operaciones de archivos

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `y` | Yank (copiar) | Copia al clipboard interno de Yazi |
| `x` | Cut (cortar) | Mueve al pegar |
| `p` | Paste | Pega en el directorio actual |
| `P` | Paste (link simbolico) | Crea symlink en vez de copiar |
| `d` | Delete (papelera) | Envia a trash, recuperable |
| `D` | Delete definitivo | Sin papelera. Ir con cuidado |
| `r` | Rename | Renombra el item actual |
| `a` | Add / Crear | Crea archivo. Si termina en `/` crea carpeta. `src/models/` crea toda la ruta |
| `o` | Open with | Menu para elegir programa |
| `;` | Comando de shell | Ejecuta comando shell en el dir actual |
| `!` | Shell interactivo | Abre shell en el directorio actual (bloqueante) |

**Truco clave para `a`**: escribir `proyecto/src/main.go` crea toda la jerarquia de carpetas mas el archivo en un solo paso.

---

## Tabs (pestanas)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `t` | Nueva tab | Abre tab en el mismo directorio |
| `1`-`9` | Ir a tab N | Salto directo |
| `Tab` | Tab siguiente | |
| `Shift+Tab` | Tab anterior | |
| `[` / `]` | Tab anterior / siguiente | Alternativa a Tab |

**Caso de uso**: tab 1 en `~/projects/`, tab 2 en `/nix/store/` para investigar closures, operás entre ambas con `p`.

---

## Busqueda y filtros

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `f` | Filter (tiempo real) | Oculta items que no matchean mientras escribis |
| `/` | Find (incremental) | Mueve cursor al primer match |
| `s` | Search (fd/find) | Busqueda recursiva en subdirectorios |
| `S` | Search (rg/ripgrep) | Busca por contenido del archivo |
| `Esc` | Limpiar busqueda/filtro | Sale del modo |

**Diferencia importante**: `f` filtra la vista (no busca en subdirectorios), `s` usa `fd` para busqueda recursiva, `S` usa `rg` para busqueda por contenido.

---

## Ordenamiento

| Tecla | Accion |
|-------|--------|
| `,` | Abrir menu de sort |

Opciones en el menu:
- `m` — por fecha de modificacion (util para logs, configs)
- `s` — por tamano (util para `/nix/store`)
- `n` — natural (alfanumerico, default)
- `e` — por extension
- `r` — invertir orden actual

---

## Bookmarks

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `m` + `<key>` | Crear bookmark | Guarda el directorio actual con esa tecla |
| `'` + `<key>` | Saltar a bookmark | |
| `'` + `'` | Volver al ultimo directorio | Toggle rapido |
| `` ` `` | Lista de bookmarks | Muestra todos los guardados |

**Sugerencia DevOps**: guarda `m p` para `~/projects/`, `m n` para `~/projects/nix-config/`, `m d` para `~/projects/dotfiles/`.

---

## Preview

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `K` | Scroll preview arriba | Navegar contenido del archivo en el panel derecho |
| `J` | Scroll preview abajo | |
| `i` | Ingresar al preview | Interactuar con el preview (ej: imagen, PDF) |
| `Esc` | Salir del preview | |

**Protocolos de imagen**: Yazi soporta Kitty Graphics Protocol (KGP), Sixel y otros.
Tu terminal es **foot** (desde 2026-07-20; antes kitty) → Yazi usa el adapter **Sixel**.
Las previews de imagen funcionan; el color es levemente menor que con KGP (se nota en
gradientes finos, no en fotos). Si una preview no aparece, verificar que foot tiene
soporte sixel compilado (`foot --version` menciona sixel) — en nixpkgs viene activado.

---

## Shell e integracion

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `!` | Shell en directorio actual | Lanza $SHELL; al salir vuelves a Yazi |
| `z` | Zoxide jump | Si tenes `zoxide` instalado: salto fuzzy a directorios frecuentes |
| `Z` | Fzf jump | Busqueda fuzzy con fzf |

**Integracion con el shell**: agrega esto a tu `~/.config/fish/config.fish` o `.zshrc` para que el shell cambie de directorio al salir de Yazi:

```bash
# Para zsh (agregar a .zshrc)
function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
```

Luego usas `yy` en lugar de `yazi` y el directorio persiste al salir.

---

## Task manager

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `w` | Task manager | Ver tareas en curso (copias grandes, etc.) |
| En task manager: `x` | Cancelar tarea | |
| `Esc` | Cerrar task manager | |

---

## Comandos especiales

| Comando | Descripcion |
|---------|-------------|
| `:` | Modo comando de Yazi (similar a vim) |
| `:shell <cmd>` | Ejecutar comando sin salir |
| `:cd <path>` | Cambiar directorio directamente |
| `:hidden` | Toggle ver archivos ocultos (equivalente a `Ctrl+h`) |

| Tecla | Descripcion |
|-------|-------------|
| `Ctrl+h` | Toggle archivos ocultos (`.dotfiles`) |
| `.` | Toggle archivos ocultos (alternativa) |
| `q` | Salir de Yazi |

---

## Tips DevOps

### Navegar /nix/store sin volverse loco

```
# Desde yazi, ve a /nix/store y filtra por nombre de paquete:
# Presiona f, escribe "neovim", ves solo los closures relevantes.
# Presiona s para busqueda recursiva si queres encontrar un binario especifico.
```

### Comparar configs antes de nixos-rebuild

Tener tab 1 en `~/projects/nix-config/`, tab 2 en `/etc/` o en el store. Copias rutas con `y` y las usas en la terminal con `!`.

### Logs en produccion (SSH)

Yazi funciona en SSH. Para navegar `/var/log/` en un server y previsualizar logs en tiempo real, usa `K`/`J` en el panel de preview en vez de abrir con less.

### Operaciones masivas

```
# Mover todos los .ics de una carpeta a otra:
# 1. Filtrar: f -> .ics
# 2. Ctrl+a (seleccionar todo lo visible)
# 3. x (cortar)
# 4. Navegar al destino
# 5. p (pegar)
```

### Ver pesos rapidamente

Ordena por tamano (`,` -> `s`) en `~/.local/share/` para encontrar que esta comiendo espacio. Util despues de `nixos-rebuild` si el store creció.

---

## Configuracion avanzada (referencia)

Los archivos de config de Yazi estan en `~/.config/yazi/`:
- `yazi.toml` — comportamiento general, openers, plugins
- `keymap.toml` — remapear teclas
- `theme.toml` — colores

Para agregar una regla de apertura personalizada en `yazi.toml`:

```toml
[opener]
edit = [
  { run = 'nvim "$@"', desc = "Neovim", block = true }
]

[open]
rules = [
  { mime = "text/*", use = ["edit"] },
  { mime = "application/json", use = ["edit"] },
]
```

`block = true` hace que Yazi espere a que cierres Neovim antes de continuar — esencial para editores TUI.
