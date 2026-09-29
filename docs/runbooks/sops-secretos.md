# Secretos con sops — agregar, leer, rotar, y si se filtra

Concepto (por qué sops, cómo es la cadena): [nixos-practica §5.5](../guias/nixos-practica.md#55-secretos-declarativos-sops-nix).
Acá: los procedimientos, probados en este equipo.

## La idea en una línea

El secreto vive **cifrado en git** (`secrets/*.yaml`) y **descifrado solo en RAM**
(`/run/user/1000/secrets.d/…`, permisos 400). Nunca en el store de Nix (que cualquiera
puede leer) ni en claro en el repo.

- **Cifrar** usa la clave PÚBLICA (el `age1…` de `.sops.yaml`): cualquiera puede cifrar.
- **Descifrar** usa la PRIVADA, derivada de `~/.ssh/id_ed25519`. Sin esa SSH, nada abre.

## Paso 0 — la variable que el CLI necesita (siempre)

sops-nix deriva la clave age de tu SSH solo, al activar. **El CLI `sops` no**: sin esto
falla con `at least one key has to be successful, but none were`.

```bash
export SOPS_AGE_KEY="$(ssh-to-age -private-key -i ~/.ssh/id_ed25519)"
```

Ponela solo en la terminal donde vas a trabajar; no en el `.zshrc` (sería tener tu
clave privada en claro en cada shell).

## Práctica sin riesgo (hacelo una vez)

Un laboratorio en `/tmp`, contra tu mismo recipient, sin tocar los secretos reales:

```bash
mkdir -p /tmp/sops-lab/secrets && cd /tmp/sops-lab
cp ~/projects/nix-config/.sops.yaml .
printf 'SALUDO: hola-mundo\n' > secrets/prueba.yaml
sops -e -i secrets/prueba.yaml     # cifra en el lugar (no necesita la variable)
cat secrets/prueba.yaml            # mirá: los VALORES cifrados, las CLAVES a la vista
sops -d secrets/prueba.yaml        # sin la variable: falla (eso es lo esperado)
export SOPS_AGE_KEY="$(ssh-to-age -private-key -i ~/.ssh/id_ed25519)"
sops -d secrets/prueba.yaml        # ahora sí: SALUDO: hola-mundo
sops secrets/prueba.yaml           # editar: abre $EDITOR descifrado, re-cifra al guardar
cd ~ && rm -rf /tmp/sops-lab
```

Notar lo que ves en el `cat`: los nombres (`SALUDO`) quedan en claro. **El nombre de un
secreto no es secreto**; no pongas información en la clave.

## Leer un secreto real

```bash
cd ~/projects/nix-config
sops -d secrets/pedco.yaml                       # todo
sops -d --extract '["TG_TOKEN"]' secrets/pedco.yaml   # uno solo
```

## Agregar un secreto nuevo

1. Editar el archivo (con la variable exportada) y agregar la línea `NOMBRE: valor`:
   ```bash
   sops secrets/pedco.yaml
   ```
2. Declararlo en `home/rolando.nix`, bloque `sops.secrets`:
   `NOMBRE.sopsFile = ../secrets/pedco.yaml;`
3. Que el servicio lo reciba: sumarlo al template (`sops.templates."pedco.env"`) si el
   unit usa `EnvironmentFile`, o leer `config.sops.secrets.NOMBRE.path` si espera un archivo.
4. El servicio debe declarar `After`/`Wants` de `sops-nix.service`, o arranca antes de que
   el secreto exista.
5. `rebuild`, y verificar:
   ```bash
   find -L ~/.config/sops-nix/secrets -printf '%P %m\n'   # aparece NOMBRE con 400
   ```

Un secreto declarado que ningún servicio lee es ruido: hoy `MOODLE_TOKEN` está
declarado y **nada lo consume** (revisado el 28-sep-2026 en nix-config, scraper-pedco y
curza-sync). Borrarlo o conectarlo.

## Crear un archivo de secretos nuevo

`creation_rules` matchea la ruta del archivo de **entrada**: el archivo tiene que estar
bajo `secrets/`, o usar `--filename-override`.

```bash
sops secrets/nuevo.yaml             # abre el editor; crea y cifra al guardar
                                    # (si guardás sin cambios, no crea nada)
# o desde un .env existente:
sops -e --input-type dotenv --output-type yaml \
  --filename-override secrets/nuevo.yaml  ~/proyecto/.env > secrets/nuevo.yaml
diff <(sops -d --output-type dotenv secrets/nuevo.yaml) ~/proyecto/.env   # round-trip
```

No borrar el `.env` original hasta que el `diff` salga vacío: el formato dotenv descarta
en silencio las líneas que no son `K=V`.

## Rotar un secreto

1. Generar el valor nuevo en su origen (BotFather, el proveedor de la API, etc.).
2. `sops secrets/pedco.yaml` → reemplazar el valor → guardar.
3. `rebuild` y reiniciar el servicio si no lo hace solo:
   `systemctl --user restart pedco-bot.service`.
4. Verificar contra el servicio, no contra el archivo: que funcione con el nuevo.
5. **Commitear el yaml.** Si no, `HEAD` conserva el valor viejo y un clon limpio o un
   `git restore` lo trae de vuelta.
6. Revocar el viejo en el origen.

## Si un secreto se filtró

Pasó el 4-ago-2026: el token del bot estaba hardcodeado en un repo público.

1. **Revocar primero**, en el origen. Rotar sin revocar deja el viejo vivo.
2. Rotar (sección anterior).
3. Revisar qué hizo el atacante con el acceso (en el caso del bot: `getWebhookInfo` —
   había registrado un webhook propio y se llevaba los mensajes).
4. Borrar el valor del lugar donde se filtró. **Cambiar el archivo no alcanza**: queda en
   la historia de git. Hace falta reescribir la historia (`git filter-repo`) y hacer
   force-push, o pasar el repo a privado.
5. Si el secreto daba acceso a datos de otras personas, avisarles.

Gotcha: al revocar un token de Telegram el prefijo numérico (`<bot_id>:`) NO cambia.
Comparar los últimos caracteres o preguntar con `getMe`.

## Máquina nueva

Copiar `~/.ssh/id_ed25519` desde el respaldo **antes** del primer `rebuild`: sin ella
sops-nix no descifra y los servicios que usan secretos no arrancan (el resto del sistema sí).
Detalle en el [README](../../README.md#instalación-en-una-máquina-nueva).
