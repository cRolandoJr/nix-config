# opencode falla o no hace lo que esperabas

Primer paso SIEMPRE, antes de tocar nada: ver el error completo.

```bash
opencode run --print-logs 'di hola' > /tmp/oc.log 2>&1
grep 'level=ERROR' /tmp/oc.log
```

(A archivo y después `grep`: si lo pasás por `tail` te podés comer justo la línea que importa.)

## No arranca: `Unexpected server error`

1. ¿Es un plugin? Probar sin ellos: `opencode run --pure 'di hola'`.
   - Si con `--pure` anda → el culpable está en `~/.config/opencode/plugins/`.
   - Si sigue fallando → no es un plugin; leer el `level=ERROR` del log.
2. Error `null is not an object (evaluating 'C.config')` (o `.event`, `.dispose`): un archivo
   de `plugins/` **exporta más de una cosa**. opencode carga como plugin CADA export.
   Dejar un solo `export`. *Pasó el 28-sep-2026 con `denyReason`.*
3. Correr el test del plugin: `nix shell nixpkgs#bun -c bun ~/.config/opencode/tests/mechanical-rules.test.mjs`
   → tiene que decir `resumen: 0 fallos`.

El aviso `Detected legacy nixpkgs OpenCode database` NO es el error: es informativo.

## Bloquea TODOS los comandos, incluso `git status`

El plugin es *fail-closed*: si no puede correr el script de reglas, no deja pasar nada. El
mensaje dice `hook de reglas mecánicas no pudo correr: ...` con el motivo. Revisar:

```bash
ls -l ~/.claude/hooks/mechanical-rules-bash.sh     # tiene que existir
command -v jq                                      # el script lo usa
echo '{"tool_input":{"command":"git status"}}' | bash ~/.claude/hooks/mechanical-rules-bash.sh
# debe salir VACÍO (= pasa); si imprime un error, ese es el problema
```

Verificado: con el script ausente bloquea `git status` con ese mensaje.

## Bloquea un comando que debería pasar

Es una regla del **script**, no del plugin: Claude Code haría lo mismo. Ver cuál regla saltó
(la clave entre corchetes, p. ej. `[gitadd]`) y decidir:
- la regla tiene razón → corregir el comando;
- es un falso positivo → ajustar la regla ([opencode-mantenimiento](opencode-mantenimiento.md#agregar-o-cambiar-una-regla-mecánica));
- es un caso puntual → el escape `REGLA-OK:<clave>` en el comando, decidido por vos, nunca por el agente.

## Una skill no se carga

```bash
opencode debug skill > /tmp/sk.json 2>&1; jq -r '.[].name' /tmp/sk.json | sort
grep 'duplicate skill name' /tmp/oc.log
```

- No aparece → revisar el `name:` del frontmatter: minúsculas y guiones, igual al nombre de la carpeta.
- `duplicate skill name` → dos carpetas con el mismo `name`; opencode no garantiza cuál usa.
  Caso conocido: `gama23-weekly-status` (copia vieja en `~/.claude/skills/synced/`).
- Aparece pero no se dispara sola → la `description` no se parece a cómo pediste la tarea.
  Forzarla con `/skill <nombre> <tarea>`.

## Un subagente hizo algo que no debía (o "no funciona")

- `opencode run --agent <subagente>` NO lo prueba: avisa `is a subagent, not a primary agent`
  y **cae a `build`**, que puede todo. Invocarlo con `@nombre` desde el principal.
- Ver qué hizo de verdad: el log trae `agent=<nombre>` y el id de la sesión (`ses_...`);
  `opencode export <ses_id> | jq -r '.. | objects | select(.type=="tool") | .tool'` lista las
  herramientas que usó.
- Permisos efectivos: `opencode debug agent <nombre>`. En `bash` gana la ÚLTIMA regla que
  coincide: `"*": allow` va primero y los `deny` después.
- Un agente con `bash` puede escribir archivos con `printf > x` aunque tenga `edit: deny`: eso
  lo frena su prompt, no el mecanismo.

## Respuestas malas o el modelo "no entiende"

Antes de culpar al modelo:
1. ¿Qué modelo corrió? El log dice `llm.model=...`. Un agente sin `model:` hereda el del principal.
2. ¿Cargó tu memoria y tus reglas? `opencode debug config | jq '.instructions'` tiene que listar
   `memoria.md` y `MEMORY.md`. Si existe `~/.config/opencode/AGENTS.md`, **deja de leer
   `~/.claude/CLAUDE.md`**: borrarlo o moverlo.
3. Si el problema es de calidad, no de config: subir de modelo SOLO ese rol (ver
   [opencode-primer-dia §7](opencode-primer-dia.md#7-la-primera-semana-medir-no-suponer)).
