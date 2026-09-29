# opencode — skills, agentes y modelos

Agente de código multi-proveedor que reemplaza a Claude Code con modelos más baratos.
Config en `~/projects/dotfiles/opencode/.config/opencode/` (enlazada a `~/.config/opencode/`;
editar el origen). Versión y paquete: `home/rolando.nix`. Todo lo de esta guía se probó el
28-sep-2026 con opencode 1.18.31.

## Qué ya trae configurado

| Pieza | Dónde | Qué hace |
|---|---|---|
| Tus reglas | `~/.claude/CLAUDE.md` | opencode lo lee solo, **mientras no exista** `~/.config/opencode/AGENTS.md` (no crearlo) |
| Tus skills | `~/.claude/skills/` + `~/.config/opencode/skills/` (superpowers) | se cargan solas o con `/skill` |
| Memoria | `instructions` en `opencode.json` | inyecta `memoria.md` + `MEMORY.md`; es la MISMA memoria que Claude Code |
| Reglas mecánicas | `plugins/mechanical-rules.js` | llama al mismo `~/.claude/hooks/mechanical-rules-bash.sh` y bloquea el comando |
| Agentes de ai-loop | `agents/*.md` | gate, implementador, verificador, investigador |

## 1. Usar las skills

**Solas.** El agente ve la lista de skills con su `description` y carga la que corresponde con
la herramienta `skill` (en pantalla aparece `→ Skill "tps"`). Por eso la `description` de cada
skill es lo que decide si se dispara: escribila con las palabras con que vas a pedir la tarea.

**Forzada: `/skill <nombre> <tarea>`** (comando propio, `commands/skill.md`):

```
/skill tps armá el TP3 de Automatización
/skill ai-loop agregar filtro por categoría al listado de torneos
/skill bug-sniper el login falla con 104 después del reinicio
```

Desde la terminal, sin abrir la interfaz:

```bash
opencode run --command skill "tps decime qué está pendiente"
```

Ver qué skills ve opencode: `opencode debug skill` (el JSON trae `name` y `location`).

Nombres de skill **únicos**: si dos carpetas tienen el mismo `name`, opencode avisa
`duplicate skill name` y no está claro cuál usa. Pasa hoy con `gama23-weekly-status`
(la de `~/.claude/skills/synced/` es la copia vieja subida a claude.ai).

## 2. Conectar un proveedor (cuando tengas plan o API key)

Sin configurar nada, opencode usa su modelo gratuito `opencode/big-pickle`: sirve para probar.

1. Abrir `opencode` y escribir `/connect`; elegir el proveedor y pegar la key. Queda en
   `~/.local/share/opencode/auth.json` (fuera de git). Equivalente: `opencode auth login`.
2. Ver los IDs de modelo disponibles: `opencode models` (o `/models` adentro).
   El formato es siempre `proveedor/modelo`.
3. Proveedor que no está en la lista pero es compatible con OpenAI (DeepSeek directo,
   OpenRouter con otra URL): en `opencode.json`

```json
"provider": {
  "deepseek": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "DeepSeek",
    "options": { "baseURL": "https://api.deepseek.com/v1", "apiKey": "{env:DEEPSEEK_API_KEY}" },
    "models": { "deepseek-chat": { "name": "DeepSeek" } }
  }
}
```

La `baseURL` y el nombre de modelo de este ejemplo NO están verificados: sacarlos de la
documentación del proveedor el día que lo configures. La key va por variable de entorno
(`{env:...}`), nunca escrita en el JSON: el JSON está en un repo público. Para guardarla cifrada, ver [runbooks/sops-secretos](../runbooks/sops-secretos.md).

## 3. Asignar un modelo a cada agente

**La regla que importa:** el que **verifica** corre en un modelo **distinto** del que
**implementa**. Si el mismo modelo se equivoca y se corrige, comete el mismo error dos veces.
Y el que planea y verifica tiene que ser el fuerte: la evidencia disponible (28-sep-2026) es que
la delegación colapsa cuando el orquestador es un modelo barato.

| Rol | Agente | Dónde se pone el modelo | Modelo sugerido |
|---|---|---|---|
| Orquestador (escribe el spec, coordina) | `build` (el principal) | `"model"` en `opencode.json` | el fuerte |
| Planner (analiza sin tocar) | `plan` (trae opencode; se cambia con **Tab**) | `"agent": { "plan": { "model": ... } }` en `opencode.json` | el fuerte |
| Gate adversarial | `gate` | línea `model:` en `agents/gate.md` | el fuerte |
| Implementador | `implementador` | `model:` en `agents/implementador.md` | el barato |
| Verificador | `verificador` | `model:` en `agents/verificador.md` | fuerte, ≠ implementador |
| Investigador | `investigador` | `model:` en `agents/investigador.md` | el barato |

Ejemplo en `opencode.json` (IDs de ejemplo: usar los que muestre `opencode models`):

```json
"model": "zai-coding-plan/glm-5.3",
"agent": { "plan": { "model": "zai-coding-plan/glm-5.3" } }
```

Y en el frontmatter de `agents/implementador.md`, debajo de `mode: subagent`:

```yaml
model: opencode/deepseek-v4.1-flash
```

Un agente **sin** `model:` usa el del agente que lo llamó.

Verificar que quedó (no confiar en haberlo escrito):

```bash
opencode debug agent verificador | jq -r '.model'
opencode debug agent implementador | jq -r '.permission[] | select(.permission=="bash") | "\(.pattern) → \(.action)"'
```

## 4. Usar los agentes

- **Tab**: cambia entre los agentes principales (`build` ↔ `plan`).
- **`@nombre`** en el mensaje: invoca un subagente a mano (`@verificador revisá el diff contra el spec`).
- **Automático**: el principal delega solo, según la `description` de cada subagente.
- **El circuito completo**: `/skill ai-loop <tarea>` desde `build`. La skill hace de guion y
  llama a gate → implementador → verificador.

Un subagente NO se puede elegir como principal: `opencode run --agent verificador` avisa
`is a subagent, not a primary agent` y **cae a `build`**, que sí edita. Para probar un
subagente, invocarlo con `@` desde el principal.

## 5. Permisos: qué frena de verdad y qué no

- `edit: deny` **quita la herramienta**: el agente ni la ve. Verificado: el verificador
  respondió "no existe `write` ni `edit`" y el archivo no se creó.
- En `bash`, **gana la última regla que coincide**: primero `"*": allow`, después los `deny`.
  Al revés, el `allow` general anula todo.
- **Límite:** un agente con `bash` puede escribir archivos igual (`printf > x`). El verificador
  y el gate no lo hacen porque su prompt lo prohíbe, no porque no puedan. Es conducta, no
  mecanismo: *capacidad ≠ permiso*.
- Las reglas mecánicas (el plugin) corren en TODOS los agentes, además de estos permisos.

## 6. Diagnóstico

| Síntoma | Causa y arreglo |
|---|---|
| `Unexpected server error` al abrir | Correr `opencode run --print-logs "hola"` y leer los `level=ERROR`. Con `--pure` arranca sin plugins: si así anda, el culpable es un plugin |
| `null is not an object (evaluating 'C.config')` | Un archivo de `plugins/` exporta más de una cosa: opencode carga como plugin CADA export |
| Aviso `legacy nixpkgs OpenCode database` | Informativo: usa la base de una instalación vieja. No es un error |
| El hook bloquea algo que no debería | El mismo caso se reproduce en Claude Code: es una regla del script, no del plugin. Test: `nix shell nixpkgs#bun -c bun ~/.config/opencode/tests/mechanical-rules.test.mjs` |
