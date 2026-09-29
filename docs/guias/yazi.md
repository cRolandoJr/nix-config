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

**Integracion con el shell (`yy`): NO configurada hoy.** Sirve para que, al salir de
Yazi, el shell quede parado en el directorio donde estabas. Si algún día la querés, la vía
canónica es home-manager y no pegar una función en `.zshrc`:

```nix
# home/rolando.nix — hoy yazi entra como paquete suelto; esto lo reemplaza
programs.yazi = {
  enable = true;
  enableZshIntegration = true;   # crea la función `yy` (shellWrapperName)
};
```

Ojo: la config de yazi ya se enlaza con `xdg.configFile."yazi"` desde dotfiles; no
declarar `programs.yazi.settings` o habría dos dueños del mismo `yazi.toml`.


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

La config vive en `~/projects/dotfiles/yazi/.config/yazi/` (enlazada a `~/.config/yazi/`;
editar el origen). Hoy existe **solo `yazi.toml`**; `keymap.toml` (remapear teclas) y
`theme.toml` (colores) se crean si hacen falta.

Tu única personalización real: PDFs con Firefox.

```toml
[opener]
pdf = [
  { run = 'firefox %s', desc = "Firefox", orphan = true, for = "linux" },
]

[open]
prepend_rules = [
  { mime = "application/pdf", use = [ "pdf", "open", "reveal" ] },
]
```

- **`%s` y no `"$@"`**: desde yazi 26 el archivo se pasa con `%s` (todos los
  seleccionados) o `%s1` (el primero). Con `"$@"` el opener corre SIN archivo: así se
  rompió el PDF el 28-sep-2026 (abría una ventana vacía de Firefox). Referencia: los
  openers por defecto usan `xdg-open %s1` y `${EDITOR:-vi} %s`.
- **`prepend_rules` y no `rules`**: `rules` REEMPLAZA todas las reglas por defecto;
  `prepend_rules` agrega las tuyas adelante y deja el resto funcionando.
- `orphan = true`: la app sigue abierta aunque cierres Yazi. Para un editor de terminal
  va al revés, `block = true`: Yazi espera a que salgas del editor.
