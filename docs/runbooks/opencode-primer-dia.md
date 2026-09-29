# El día que dejás Claude Code — dejar opencode listo para trabajar

Referencia de todo lo que se nombra acá: [guias/opencode](../guias/opencode.md).
Duración: ~20 minutos. Hacelo un día tranquilo, no con una entrega encima.

## 1. Elegir el plan

Investigación del 28-sep-2026 (precios de ese día; volver a mirarlos):

| Plan | Costo | Cuándo |
|---|---|---|
| OpenCode Go | 10 USD/mes | el más barato; DeepSeek Flash y GLM-Flash con cuota amplia, Kimi K3 racionado |
| GLM Coding Lite (Z.ai) | 18 USD/mes | GLM-5.3, el mejor modelo abierto en el índice independiente de ese día |
| Pago por uso (OpenRouter) | variable | uso liviano o para probar modelos sueltos |

Código de clientes o del trabajo: **nunca por la API directa de DeepSeek** (guarda los datos en
China). Por OpenCode Go (retención cero) o por OpenRouter con un proveedor de EE. UU.

## 2. Conectarlo

```bash
opencode            # dentro: /connect → elegir proveedor → pegar la key
opencode models     # anotar los IDs exactos (formato proveedor/modelo)
```

## 3. Asignar un modelo por rol

Con los IDs del paso 2 (los de abajo son de ejemplo):

1. `~/projects/dotfiles/opencode/.config/opencode/opencode.json` — el principal y el planner:
   ```json
   "model": "proveedor/modelo-fuerte",
   "agent": { "plan": { "model": "proveedor/modelo-fuerte" } }
   ```
2. En cada `agents/*.md`, una línea `model:` debajo de `mode: subagent`:
   - `gate.md` y `verificador.md` → el fuerte
   - `implementador.md` e `investigador.md` → el barato

**Regla:** verificador ≠ implementador. Si tu plan tiene un solo modelo bueno, el verificador
usa ese y el implementador otro distinto aunque sea más flojo.

## 4. Verificar lo que escribiste

```bash
for a in build plan gate implementador verificador investigador; do
  printf '%-14s %s\n' "$a" "$(opencode debug agent $a | jq -r '.model // "hereda"')"
done
```

Tiene que salir el modelo que pusiste en cada uno. `hereda` en un subagente = usa el del agente
que lo llama; en `build` y `plan` = usa el `"model"` global de `opencode.json` (o el gratuito
si no hay ninguno).

## 5. Prueba de humo

Correr en una carpeta que NO sea un repo, por ejemplo `mkdir -p /tmp/humo && cd /tmp/humo`.
Comillas **simples** siempre: con dobles, zsh reemplaza `$` y `!` antes de que llegue a opencode.

| Prueba | Comando | Esperado |
|---|---|---|
| El hook bloquea | `opencode run 'Usá bash para ejecutar exactamente: git add -A'` | `✗ git add -A failed` y `BLOQUEADO ... [gitadd]` |
| Lo normal pasa | `opencode run 'Usá bash para ejecutar exactamente: git --version'` | `git version ...` |
| Skills cargan | `opencode run --command skill 'tps decime en una línea qué hace'` | `→ Skill "tps"` y un resumen |
| Verificador sin escritura | `opencode run '@verificador creá el archivo x.txt con hola'` | reporta que no tiene `write`/`edit`; `x.txt` NO existe |

Si alguna falla: [opencode-falla](opencode-falla.md).

## 6. Guardar

```bash
cd ~/projects/dotfiles && git status --short      # solo opencode/…/opencode.json y agents/
git add opencode/.config/opencode/opencode.json opencode/.config/opencode/agents
git commit -m "opencode: modelos por rol (<plan elegido>)" && git push
```

La key NO está en esos archivos (vive en `~/.local/share/opencode/auth.json`, fuera de git).
Si la usás por variable de entorno, guardala cifrada: [sops-secretos](sops-secretos.md).

## 7. La primera semana: medir, no suponer

Anotá en qué tareas el modelo barato falló (cuántas veces tuviste que corregirlo). Si el
implementador falla seguido, subilo de modelo; si el verificador deja pasar cosas, es la
señal más grave: ese sí tiene que ser el mejor que tengas. El paso siguiente es medirlo con
los casos golden de ailoop (`ailoop golden`), que dan un número comparable entre modelos.
