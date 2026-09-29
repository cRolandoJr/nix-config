# Neovim — Guia Completa (Tu Config, act. Julio 2026)

> Este cheatsheet esta basado en tu config real: `~/projects/dotfiles/nvim/.config/nvim/`.
> No hay keymaps inventados. Cada entrada esta verificada en los archivos fuente.
> `<leader>` = `Space` · nvim 0.12.3 · plugins via lazy.nvim (import de `lua/plugins/`)
>
> **Cambio 2026-07-20:** se quitó `hardtime.nvim` (bloqueaba hjkl repetido para forzar
> hábitos). Ya no hay fricción artificial — el aprendizaje ahora es deliberado, vía la
> **Parte 4 · Ruta a Pro** de abajo. `nui.nvim` quedó huérfano (era su dep); lazy lo
> limpia solo en el próximo `:Lazy sync`.

---

## Parte 1 — Cheatsheet completo de tu config

### General (keymaps.lua)

| Tecla | Modo | Accion | Fuente |
|-------|------|--------|--------|
| `Ctrl+s` | n/i/v | Guardar (+ autoformat al guardar) | keymaps.lua |
| `<leader>qq` | n | Salir de Neovim (`:qa`) | keymaps.lua |
| `Esc` | n | Limpiar highlight de busqueda | keymaps.lua |
| `Ctrl+h/j/k/l` | n | Moverse entre splits | keymaps.lua |
| `Ctrl+Flechas` | n | Redimensionar split | keymaps.lua |
| `Alt+j/k` | n/v/i | Mover linea(s) arriba/abajo | keymaps.lua |
| `>` / `<` | v | Indentar/desindentar sin perder seleccion | keymaps.lua |
| `p` | v | Pegar sin pisar el registro (evita perder el yank) | keymaps.lua |
| `Shift+l` / `Shift+h` | n | Buffer siguiente / anterior | keymaps.lua |
| `<leader>bd` | n | Cerrar buffer (`:bdelete`) | keymaps.lua |
| `]d` / `[d` | n | Diagnostico siguiente / anterior (con float) | keymaps.lua |
| `<leader>cd` | n | Diagnostico flotante en linea actual | keymaps.lua |

---

### LSP (lsp.lua — activo cuando hay servidor adjunto)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `gd` | Ir a definicion | Salta donde se declara la funcion/tipo |
| `gD` | Ir a declaracion | Diferente de definicion en algunos lenguajes |
| `gr` | Referencias | Lista todos los usos (usa el quickfix) |
| `gi` | Implementacion | Donde se implementa la interfaz/trait |
| `gt` | Type definition | El tipo concreto de una variable |
| `K` | Hover | Documentacion + tipos en popup flotante |
| `Ctrl+k` | Signature help | Ayuda de parametros mientras escribis (n/i) |
| `<leader>rn` | Renombrar | Rename global en todo el proyecto |
| `<leader>ca` | Code action | Sugerencias del LSP (n/v — aplica a seleccion en visual) |
| `<leader>ih` | Toggle inlay hints | Muestra/oculta hints de tipos inline (nvim 0.10+) |

**LSPs activos en tu setup**: gopls, pyright, ts_ls, html, cssls, jsonls, yamlls, bashls, lua_ls, rust-analyzer (via rustaceanvim), dart/flutter (via flutter-tools).

**Como saber si el LSP esta activo**: `:checkhealth vim.lsp` o mira el statusline (lualine muestra diagnosticos).

---

### Busqueda y archivos (telescope.lua)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `<leader>ff` | Find files | Busca por nombre en el proyecto |
| `<leader>fg` | Live grep | Busca texto en TODOS los archivos |
| `<leader>fb` | Buffers abiertos | Cambiar entre buffers con fuzzy search |
| `<leader>fh` | Help tags | Busca en la documentacion de nvim |
| `<leader>fr` | Recientes | Archivos abiertos recientemente |
| `<leader>fk` | Keymaps | Muestra todos los keymaps registrados |
| `<leader>fd` | Diagnosticos | Lista todos los diagnosticos del proyecto |
| `<leader>fs` | Simbolos (archivo) | Funciones/vars del archivo actual |
| `<leader>fS` | Simbolos (workspace) | Funciones/vars en todo el proyecto |
| `<leader>fw` | Grep palabra | Grep de la palabra bajo el cursor |
| `<leader>/` | Buscar en buffer | Fuzzy search dentro del archivo actual |
| `<leader>ft` | Buscar TODOs | Busca comentarios TODO/FIXME/HACK (todo-comments) |

**Dentro de Telescope**: `Ctrl+j`/`Ctrl+k` para mover seleccion (configurado en opts), `Enter` para abrir, `Ctrl+t` para abrir en tab, `Ctrl+v` para vertical split, `Ctrl+x` para horizontal split.

---

### Edicion avanzada (editor.lua)

| Tecla | Accion | Plugin | Descripcion |
|-------|--------|--------|-------------|
| `s` | Flash jump | flash.nvim | Escribe 2 letras, salta donde quieras |
| `S` | Flash treesitter | flash.nvim | Selecciona nodos de AST visualmente |
| `r` | Flash remote (op) | flash.nvim | En modo operador: target remoto |
| `F2` | Toggle NvimTree | nvim-tree | Explorador lateral de archivos |
| `<leader>e` | Localizar en NvimTree | nvim-tree | Abre el arbol en el archivo actual |
| `-` | Oil (dir como buffer) | oil.nvim | Edita el filesystem como si fuera texto |

**nvim-surround** (sin keymap especial, usa los defaults):
- `ysiw"` — rodea la palabra con comillas
- `cs'"` — cambia `'` por `"` alrededor del cursor
- `ds"` — elimina las comillas alrededor

---

### Textobjects de Treesitter (treesitter.lua)

Estos se usan como operadores en modo visual `x` u operador-pendiente `o`.

| Tecla | Seleccion/movimiento | Descripcion |
|-------|---------------------|-------------|
| `af` | Funcion exterior | Incluye la firma + body |
| `if` | Funcion interior | Solo el body |
| `ac` | Clase exterior | Incluye el nombre + body |
| `ic` | Clase interior | Solo el body |
| `aa` | Parametro exterior | Con la coma |
| `ia` | Parametro interior | Sin la coma |
| `]f` / `[f` | Proxima / anterior funcion | Movimiento entre funciones |
| `]c` / `[c` | Proxima / anterior clase | Movimiento entre clases |

**Como se usa**: `dif` elimina el body de la funcion actual. `vaf` selecciona toda la funcion. `=af` reformatea la funcion. `]f` salta a la siguiente funcion.

---

### TODO comments (editor.lua)

| Tecla | Accion |
|-------|--------|
| `]t` | Saltar al siguiente TODO/FIXME/HACK |
| `[t` | Saltar al anterior |
| `<leader>ft` | Ver todos en Telescope |

Estos comments se resaltan en el codigo: `-- TODO:`, `-- FIXME:`, `-- HACK:`, `-- NOTE:`, `-- WARN:`.

---

### Git (git.lua)

#### Gitsigns (hunks — cambios individuales dentro de un archivo)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `]h` | Hunk siguiente | Salta al proximo cambio en el archivo |
| `[h` | Hunk anterior | |
| `<leader>hs` | Stage hunk | Agrega el hunk actual al index de git |
| `<leader>hr` | Reset hunk | Descarta los cambios del hunk (revertir) |
| `<leader>hS` | Stage buffer completo | Stagea todos los cambios del archivo |
| `<leader>hu` | Undo stage hunk | Deshace el stage del ultimo hunk |
| `<leader>hR` | Reset buffer | Descarta todos los cambios del archivo |
| `<leader>hp` | Preview hunk | Muestra el diff del hunk en popup |
| `<leader>hb` | Blame linea (full) | Muestra quien cambio esta linea y cuando |
| `<leader>hB` | Toggle blame inline | Muestra blame para cada linea permanentemente |
| `<leader>hd` | Diff archivo | Abre split con el diff del archivo completo |

#### Snacks — Lazygit

| Tecla | Accion |
|-------|--------|
| `<leader>gg` | Abrir Lazygit | TUI completo de git: commits, branches, stash, etc. |

#### Vim-Fugitive (comandos clasicos)

| Comando | Descripcion |
|---------|-------------|
| `:Git status` o `:G` | Status interactivo (hace stage con `-`, commit con `cc`) |
| `:Git diff` | Diff del archivo actual |
| `:Gdiffsplit` | Split con el diff |
| `:Git blame` | Blame del archivo (navega con Enter) |
| `:Git log` | Log del proyecto |
| `:Gwrite` | git add del archivo actual |
| `:Gread` | Revertir al estado del repo |

---

### Diagnosticos y errores (trouble.lua)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `<leader>xx` | Trouble: todos los diagnosticos | Vista unificada de errores del proyecto |
| `<leader>xX` | Trouble: buffer actual | Solo errores del archivo abierto |
| `<leader>xs` | Trouble: simbolos | Lista de funciones/tipos del archivo |
| `<leader>xl` | Trouble: LSP refs/defs | Referencias y definiciones en panel lateral |
| `<leader>xq` | Trouble: quickfix | El quickfix clasico de vim en UI mejorada |
| `<leader>xL` | Trouble: location list | Location list en UI mejorada |

**En Trouble**: `q` cierra el panel (configurado en autocmds.lua para esos filetypes especiales).

---

### Formato y linting (formatting.lua / linting.lua)

| Tecla / Trigger | Accion | Descripcion |
|----------------|--------|-------------|
| `<leader>cf` | Formatear | Manual: formatea el archivo o seleccion visual |
| `Ctrl+s` (guardar) | Autoformat | Se ejecuta automaticamente al guardar |
| `:FormatDisable` | Desactivar global | Apaga autoformat para toda la sesion |
| `:FormatDisable!` | Desactivar buffer | Solo en el archivo actual |
| `:FormatEnable` | Reactivar | Vuelve a activar el autoformat |
| `:ConformInfo` | Info de formatters | Muestra que formatter esta activo y por que |

**Formatters por lenguaje** (se ejecutan en `Ctrl+s`):
- Lua: `stylua`
- Python: `ruff_format` + `ruff_organize_imports`
- Go: `goimports` + `gofmt`
- Rust: `rustfmt`
- JS/TS/HTML/CSS/JSON/YAML/MD: `prettierd`
- Shell: `shfmt`
- Dart/Flutter: `dart_format`
- GTK CSS (waybar): **autoformat desactivado** (prettierd romperia `@define-color`)

**Linters automaticos** (se ejecutan al guardar o salir de insert):
- Python: `ruff`, Go: `golangci-lint`, JS/TS: `eslint_d`, Shell: `shellcheck`, Markdown: `markdownlint`, YAML: `yamllint`, Dockerfile: `hadolint`

---

### Terminal (terminal.lua)

| Tecla | Accion | Descripcion |
|-------|--------|-------------|
| `F4` | Terminal flotante | Toggle — abre/cierra la terminal |
| `<leader>tf` | Terminal flotante | Idem F4 |
| `<leader>th` | Terminal horizontal | Split abajo |
| `<leader>tv` | Terminal vertical | Split lateral (80 cols) |

**Dentro de la terminal**: `Ctrl+\` + `Ctrl+n` para volver a modo normal de Neovim. O cierra con `exit`.

---

### Buffers y UI (ui.lua / snacks.lua)

| Tecla | Accion | Plugin |
|-------|--------|--------|
| `<leader>bp` | Pin buffer | bufferline |
| `<leader>bo` | Cerrar otros buffers | bufferline |
| `[B` / `]B` | Mover buffer izq/der | bufferline |
| `<leader>bD` | Cerrar buffer (smart) | snacks bufdelete — no cierra el ultimo |
| `<leader>nh` | Historial de notificaciones | snacks notifier |

---

### Folds (codigo colapsable)

Los folds los genera Treesitter automaticamente. Arrancan abiertos (`foldlevelstart = 99`).

| Tecla | Accion |
|-------|--------|
| `zc` | Cerrar fold bajo cursor |
| `zo` | Abrir fold bajo cursor |
| `za` | Toggle fold |
| `zM` | Cerrar TODOS los folds |
| `zR` | Abrir TODOS los folds |
| `zj` / `zk` | Saltar al proximo / anterior fold |

---

### Lang-specific: Rust (rustaceanvim)

Rustaceanvim extiende los keymaps LSP estandar. Los mismos `gd`, `K`, `<leader>ca` aplican, pero con informacion extra de rust-analyzer:
- `<leader>ca` en Rust ofrece acciones especificas: "Add import", "Fill match arms", "Extract variable", etc.
- `K` muestra documentacion con tipos de Rust completos.
- Cargo features activas: `allFeatures = true`, check con Clippy.

---

### Lang-specific: Flutter/Dart (flutter-tools)

Flutter Tools agrega comandos por encima del LSP estandar:

| Comando | Descripcion |
|---------|-------------|
| `:FlutterRun` | Lanzar la app |
| `:FlutterReload` | Hot reload |
| `:FlutterRestart` | Hot restart |
| `:FlutterQuit` | Detener la app |
| `:FlutterDevices` | Listar dispositivos |
| `:FlutterEmulators` | Listar emuladores |
| `:FlutterOutlineToggle` | Panel de widget tree |
| `:FlutterDevLog` | Log de la app en nueva tab |

---

### Completion — blink.cmp

| Tecla | Accion en modo insert |
|-------|-----------------------|
| `Tab` | Seleccionar siguiente / avanzar en snippet |
| `Shift+Tab` | Seleccionar anterior / retroceder en snippet |
| `Enter` | Aceptar la seleccion |
| `Ctrl+Space` | Mostrar/ocultar menu + documentacion |

**Fuentes activas**: LSP, paths de archivo, snippets (LuaSnip + friendly-snippets), buffer.
**Ghost text**: habilitado — ves la sugerencia en gris antes de aceptarla.

---

### Markdown (render-markdown.nvim)

Activo automaticamente en archivos `.md`. Renderiza:
- Headings con iconos y colores
- Code blocks con borde y ancho completo
- Checkboxes: `- [ ]` y `- [x]`
- Conceals inline (negrita, italica visualmente)

Para ver el markdown "crudo" sin renderizado: `:set conceallevel=0`

---

## Parte 2 — Workflows productivos

### Navegar el proyecto sin mouse

**Flujo estandar** para abrir un archivo en un proyecto grande:
1. `<leader>ff` — buscar por nombre de archivo con fuzzy
2. Si buscas donde se usa algo: `<leader>fw` con el cursor sobre el simbolo
3. Para navegar el arbol visualmente: `F2` (NvimTree) o `-` (Oil, mas potente para operaciones)

**Busqueda + reemplazo a nivel proyecto**:
1. `<leader>fg` (live grep) — encuentra donde ocurre el texto
2. En los resultados, `Ctrl+q` manda todo al quickfix
3. `:cfdo %s/viejo/nuevo/g | w` — reemplaza en todos los archivos del quickfix

Este flujo es equivalente a "Ctrl+Shift+H" de VSCode pero con mas control.

**Alternativa moderna con inccommand**: `:s/viejo/nuevo/g` muestra el reemplazo en tiempo real (gracias a `opt.inccommand = "split"`).

---

### Git workflow diario

**Flujo tipico de un cambio**:
1. Editas el archivo — gitsigns muestra hunks en el signcolumn automaticamente
2. `<leader>hp` — preview del hunk para revisar antes de stagear
3. `<leader>hs` — stage del hunk especifico (no del archivo entero)
4. `<leader>gg` — abre Lazygit para escribir el commit message y ver el diff completo
5. En Lazygit: `c` para commit, `p` para push, `q` para cerrar

**Cuando algo salio mal**:
- `<leader>hr` — reset del hunk (descarta el cambio antes de hacer stage)
- `<leader>hR` — reset del archivo completo (cuidado: no se puede deshacer facilmente)
- `:Gread` (fugitive) — resetea al ultimo commit

---

### LSP workflow (el equivalente a "Ctrl+Click" de VSCode)

**Exploracion de codigo desconocido**:
1. `K` sobre cualquier simbolo — documentacion inline
2. `gd` — ir a la definicion (si queres volver: `Ctrl+o` — jumplist de nvim)
3. `gr` — ver todas las referencias (donde se usa esto)
4. `<leader>fs` — todos los simbolos del archivo en Telescope

**Refactoring**:
1. `<leader>rn` — rename: cambia el nombre en todos los usos del proyecto
2. `<leader>ca` — code actions: el LSP propone arreglos automaticos

**Debug de LSP**: si algo no funciona:
- `:checkhealth vim.lsp` — estado de los servidores
- `:ConformInfo` — que formatter esta activo en este buffer
- `:LspInfo` — configuracion del servidor activo

---

### Edicion masiva sin multi-cursor

Neovim no tiene multi-cursor como VSCode (ni la mayoria de plugins de multi-cursor son estables en nvim). Las alternativas son mas poderosas una vez que las internalizas:

**Macros** — para operaciones repetidas con logica:
1. `qa` — grabar macro en registro `a`
2. Hace la operacion (ej: ir al inicio de la linea, borrar palabra, escribir algo, bajar)
3. `q` — detener grabacion
4. `10@a` — repetir 10 veces (o `@@` para repetir la ultima)

**Visual block** — para editar columnas:
1. `Ctrl+v` — modo visual block
2. Seleccionar columnas con j/k/l/h
3. `I` para insertar al inicio de todas las lineas seleccionadas
4. `A` para agregar al final
5. `d`/`c` para borrar/cambiar

**Substitute global**:
- `:%s/viejo/nuevo/gc` — reemplaza en todo el archivo con confirmacion
- `:'<,'>s/viejo/nuevo/g` — solo en la seleccion visual

---

### Sessions y estado

Tu config tiene `snacks.nvim` con `quickfile` (carga rapida de archivos grandes) pero **no tiene session management configurado explicitamente**. Tus buffers no se restauran entre sesiones automaticamente.

Si queres persistencia de sesion, el camino es agregar `snacks.picker` + persistence, o agregar `folke/persistence.nvim` (compatible con tu stack). Avisame y lo configuramos.

Por ahora: usas `<leader>fr` (oldfiles) para volver a lo que estabas trabajando.

---

## Parte 3 — Neovim vs VSCode: analisis honesto

### Tabla comparativa

| Capacidad | VSCode | Neovim (tu config) | Veredicto |
|-----------|--------|-------------------|-----------|
| Onboarding inicial | Excelente (GUI, clics) | Curva de 2-4 semanas | VSCode gana |
| Startup time | ~1-3s | <100ms | Neovim gana |
| Uso de RAM | 200-800MB | 20-60MB | Neovim gana |
| LSP features (completado, hover, rename) | Out-of-the-box | Requiere config | Empate en resultado |
| Debug (DAP) | Excelente (F5 funciona) | nvim-dap existe pero UX inferior | VSCode gana |
| Live Preview HTML/CSS | Live Server extension | No existe equivalente | VSCode gana |
| Frontend (React/Vue, DevTools) | Integrado | Funcional pero sin DevTools | VSCode gana levemente |
| DevOps (Go, Python, Nix, YAML, HCL) | Funcional | Mejor (terminal nativa, mas rapido) | Neovim gana |
| Remote SSH/Containers | Remote extensions excelentes | Sin equivalente directo | VSCode gana |
| Git workflow | GitLens es muy bueno | Lazygit + gitsigns comparable | Empate |
| Multi-cursor UX | Intuitivo (Alt+Click) | Macros/visual-block mas potente pero menos obvio | VSCode gana en UX, Neovim en poder |
| Busqueda en proyecto | Ctrl+Shift+F suficiente | Telescope + ripgrep mas potente | Neovim gana |
| Customizacion | GUI settings pero menos control | Lua expresivo, declarativo | Neovim gana para DevOps |
| IA (Copilot, Claude, etc.) | Extensiones excelentes | Extensiones excelentes (avante, copilot) | Empate |
| Configuracion en NixOS | Extension marketplace = impuro | Home-manager lo declara todo | Neovim gana para tu setup |
| Markdown render | Markdown Preview extension | render-markdown.nvim excelente | Empate |

---

### Recomendacion para tu caso especifico

**Tu perfil**: DevOps en formacion, NixOS, Go/Python/Bash, dotfiles declarativos, Hyprland (flujo keyboard-first). Ocasionalmente Flutter.

**Mi recomendacion honesta: Neovim como editor principal, VSCode para casos puntuales.**

**Por que Neovim es la opcion correcta para tu flujo DevOps**:
- Vives en la terminal. Neovim vive en la terminal. VSCode vive a su lado.
- Tu config en NixOS declara los LSPs y formatters en el sistema. Con VSCode tendrias que mantener extensiones fuera del flake.
- Go, Python, Bash, YAML, Nix: todos tienen soporte LSP de primera clase en tu config actual.
- El keyboard-first de Hyprland y el keyboard-first de Neovim se refuerzan mutuamente.

**Cuanto tiempo para ser productive en Neovim**:
- Semana 1-2: movimiento basico, buffers, Telescope. Probablemente mas lento que VSCode.
- Semana 3-4: LSP workflow fluye. Empezas a igualar VSCode en velocidad.
- Mes 2+: el gap se invierte. Las operaciones que en VSCode requieren el mouse, en Neovim son teclado puro.

**Cuando seguir abriendo VSCode** (y no hay drama en eso):
1. **Debug interactivo** — hasta que configures nvim-dap, VSCode F5 es mas rapido.
2. **Live Preview HTML/CSS** — para frontend con hot reload visual.
3. **Flutter con hot reload visual** — flutter-tools en nvim es funcional pero el DevTools de VSCode tiene ventajas de UI.
4. **Pair programming** con alguien que no conoce vim — LiveShare de VSCode es mejor que alternatives de nvim.

**El workflow hibrido recomendado**:
- Neovim para todo lo que es texto: configs, Go, Python, Bash, YAML, Nix, Markdown.
- VSCode (o Cursor) cuando necesitas debug visual o live preview.
- Ambos comparten los mismos formatters (prettierd, ruff, gofumpt) asi el estilo es consistente.

---

### Plugins que tenes pero probablemente no usas al maximo

Estas herramientas estan en tu config pero su poder real no es obvio:

**oil.nvim** (`-`): editas el sistema de archivos como un buffer. Renombras 10 archivos editando el buffer y guardando. Borras con `dd`. Creas con `o`. Mas potente que NvimTree para refactors de estructura. Vale la pena aprender.

**Flash.nvim** (`s`): saltas a cualquier lugar en pantalla escribiendo 2 letras. Reemplaza el 80% de los casos donde usarias el mouse para "hacer clic donde quiero editar". Internalizarlo toma una semana pero luego no lo podes dejar.

**nvim-surround**: `ysiw"` rodea la palabra con comillas. `cs'"` cambia el tipo de comilla. Suena menor pero en Go (backticks en structs) y en JS (template literals) se usa constantemente.

**Treesitter textobjects** (`af`, `if`, `]f`): seleccionar y moverse entre funciones semanticamente en vez de por lineas. `dif` borra el body de la funcion actual. Muy util para refactoring.

**which-key**: si alguna vez no recordas un keymap, presiona `<leader>` y espera 300ms. Aparece el menu. Es el "safety net" completo de tu config.

---

## Parte 4 — Ruta a Pro (progresión deliberada, sin hardtime)

Sacamos hardtime porque la fricción forzada estanca: te hace evitar el error, no
dominar el movimiento. El camino a pro es al revés — **un movimiento nuevo por vez,
usado a propósito hasta que sale sin pensar.** Regla: no sumes el siguiente hasta
que el actual sea reflejo. Practicá sobre código real (Wind), no sobre ejercicios.

### Nivel 0 — Higiene (si esto no es reflejo, empezá acá)
- `hjkl` sí, pero **nunca repetido**: si vas a apretar `jjjj`, es `4j` o mejor un salto.
- Salir de insert sin estirar la mano: ya tenés `Ctrl+s` para guardar; para salir de
  insert, `jk` o `Esc`. No uses flechas — son el hábito que hardtime castigaba.

### Nivel 1 — Moverte por la línea (semana 1)
| Movimiento | En vez de | Cuándo |
|---|---|---|
| `w` `b` `e` | `l` repetido | saltar por palabras |
| `f<char>` / `t<char>` | contar caracteres | ir al `(`, `"`, `,` exacto de la línea (`;`/`,` repite) |
| `0` `^` `$` | `h` hasta el borde | inicio / primer no-blank / fin de línea |
| `ci"` `ci(` `cit` | seleccionar a mano | cambiar DENTRO de comillas/paréntesis/tag — el pan de cada día |

**Drill de la semana:** cada vez que edites un string o argumento, forzate a llegar
con `f`/`t` + `ci`. En una semana no volvés a seleccionar a mano.

### Nivel 2 — Moverte por el archivo (semana 2)
| Movimiento | Qué hace |
|---|---|
| `s` + 2 letras (**flash**, ya lo tenés) | saltar a cualquier punto visible — reemplaza el 80% del mouse |
| `}` `{` | próximo / anterior párrafo o bloque |
| `%` | saltar al paréntesis/llave que cierra |
| `gg` `G` `NNgg` | inicio / fin / línea N |
| `Ctrl+o` `Ctrl+i` | volver / avanzar en el jumplist (después de un `gd`) |
| `''` | volver a donde saltaste (dos backticks) |

**Drill:** desterrá `<leader>ff` para saltar DENTRO del archivo abierto — usá `s` (flash).

### Nivel 3 — Editar con gramática (semana 3-4, acá se vuelve pro)
Vim es un lenguaje: **verbo + objeto de texto**. Internalizá esto y todo se combina.
- Verbos: `d`elete `c`hange `y`ank `v`isual `>` indent `=` format `gc`omment
- Objetos: `iw`/`aw` palabra · `i"`/`a(` delimitadores · `ip`/`ap` párrafo ·
  `if`/`af` función · `ic`/`ac` clase (treesitter, ya lo tenés) · `it`/`at` tag
- Se multiplican: `daf` borra la función · `cit` cambia dentro del tag · `yi(` copia
  args · `>af` indenta la función · `vic` selecciona el body de la clase.
- `.` repite el último cambio. `ciw`+palabra, después `n.` `n.` para repetir en cada match.

**Drill:** una refactor real esta semana hecha SOLO con verbo+objeto y `.`, cero visual manual.

### Nivel 4 — Multiplicadores (cuando lo de arriba es reflejo)
- **Macros** (`qa … q`, `@a`, `@@`): cualquier edición repetitiva con lógica. Ya en Parte 2.
- **`:cdo`/`:cfdo`** sobre el quickfix de Telescope: refactor cross-archivo. Ya en Parte 2.
- **Visual block** (`Ctrl+v`, `I`/`A`): editar columnas. Ya en Parte 2.
- **`ci`/`di` con treesitter textobjects**: refactor semántico, no por líneas.

### Autoexamen "¿ya soy pro?"
Sos pro cuando: no mirás el teclado, no usás flechas ni mouse, pensás "cambiar
argumento" y sale `ci(` sin traducir, y usás `.` por reflejo. No es velocidad de tipeo
— es que la intención llega al buffer sin pasos intermedios conscientes.

### Cuando profundicemos (lo que queda para otra sesión)
- Registros con nombre (`"ay`, `"ap`), el registro `0` (último yank puro), `"+` (portapapeles).
- `:g/patrón/comando` (global) y `:normal` — el arma pesada para ediciones masivas.
- Configurar `nvim-dap` (debug visual) para dejar de abrir VSCode en ese caso (Parte 3).
- Session management (`persistence.nvim`) si querés que los buffers sobrevivan reinicios.
- Avisá y armamos un plan por nivel con drills sobre tus repos reales.
