# opencode — mantenimiento

Cada cambio de config va en `~/projects/dotfiles/opencode/.config/opencode/` (el origen, no el
symlink) y se commitea ahí. Después de tocar algo, la prueba de humo de
[opencode-primer-dia §5](opencode-primer-dia.md#5-prueba-de-humo).

## Agregar o cambiar una regla mecánica

Hay UNA sola fuente para Claude Code y opencode: `~/.claude/hooks/mechanical-rules-bash.sh`.
El plugin de opencode no tiene reglas propias; llama a ese script.

1. Editar el script (cada regla nace de un error real; patrones angostos: un hook que salta de
   más termina desactivado).
2. Correr los DOS tests:
   ```bash
   bash ~/.claude/hooks/mechanical-rules-bash.test.sh
   nix shell nixpkgs#bun -c bun ~/.config/opencode/tests/mechanical-rules.test.mjs
   ```
3. Anotar la regla en `~/.claude/CLAUDE.md`, sección "Reglas mecánicas", con su *Falla real*.

## Agregar una skill

1. Carpeta en `~/.claude/skills/<nombre>/SKILL.md` (así la ven las dos herramientas).
   Frontmatter: `name` = nombre de la carpeta, minúsculas y guiones; `description` de hasta
   1024 caracteres con las palabras con que vas a pedir la tarea.
2. Verificar: `opencode debug skill > /tmp/sk.json; jq -r '.[].name' /tmp/sk.json | grep <nombre>`.
3. Commitear en el repo privado: `cd ~/.claude/skills && git add <nombre> && git commit && git push`.

Una skill que SOLO es para opencode va en `~/.config/opencode/skills/` (dotfiles, repo público:
nada sensible).

## Agregar o cambiar un agente

`agents/<nombre>.md` = un agente llamado `<nombre>`. Copiar uno existente como base. Campos:
`description` (decide cuándo se delega solo), `mode: subagent`, `model`, `temperature`,
`permission`. Verificar con `opencode debug agent <nombre>`.

## Actualizar opencode

La versión la maneja Nix (`autoupdate: false` en `opencode.json`; el binario está en un store
de solo lectura). Se actualiza con el sistema: [actualizar-sistema](actualizar-sistema.md).

```bash
opencode --version    # antes y después
```

Después de actualizar: prueba de humo. Si se rompió, [opencode-falla](opencode-falla.md).

## Actualizar las skills de superpowers

Son una copia congelada (versión 6.4.1, ver `skills/ORIGEN.md`): no se actualizan solas, a
propósito. Para traer una versión nueva:

```bash
V=<versión nueva>; SRC=~/.claude/plugins/cache/claude-plugins-official/superpowers/$V/skills
DST=~/projects/dotfiles/opencode/.config/opencode/skills
ls "$SRC"                          # comparar con las que ya tenés
diff -r "$SRC/brainstorming" "$DST/brainstorming"   # leer qué cambió ANTES de copiar
```

Copiar las que cambiaron, actualizar la versión y la fecha en `ORIGEN.md`, y commitear. No
copiar `using-superpowers` ni `diagnosing-superpowers`: dependen de Claude Code.

## Rotar la API key

1. Generar la nueva en el panel del proveedor.
2. `opencode` → `/connect` → el mismo proveedor → pegar la nueva (reemplaza la anterior).
3. Prueba de humo.
4. Revocar la vieja en el panel.

Si la key entra por variable de entorno (`{env:...}` en `opencode.json`), rotarla es el
procedimiento de [sops-secretos](sops-secretos.md#rotar-un-secreto).

## Cambiar de modelo o de plan

Cambiar el `model:` del rol que corresponda y verificar con `opencode debug agent`. Mantener la
regla: verificador ≠ implementador.
