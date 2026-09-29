# Disco lleno — liberar espacio

Un solo disco btrfs cifrado (`cryptroot`) con subvolúmenes. Lo que ocupa y cómo se
libera depende del subvolumen: **no es lo mismo borrar en home que en el store**.

## 1. Medir antes de borrar

```bash
df -h /                      # lo único que dice cuánto disco REAL queda
du -sh /nix/store            # el store (tamaño SIN comprimir, ver §4)
du -sh ~/* 2>/dev/null | sort -h | tail
```

## 2. El store de Nix — se libera en el acto

`/nix` no tiene snapshots: lo que borra el gc vuelve al disco enseguida.

```bash
nh os info                   # generaciones del sistema
gc                           # alias: gc de todo lo más viejo que 7 días (root + usuario)
```

`gc` usa `--delete-older-than 7d`, igual que el gc semanal automático (`nix.gc` en
`modules/base.nix`). **No usar `nix-collect-garbage -d`**: borra TODAS las generaciones
viejas y deja el sistema sin rollback.

Para dejar exactamente N generaciones (pide clave):

```bash
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5
sudo nix-collect-garbage     # sin -d: solo lo que ya nadie referencia
```

### Si el gc libera poco: raíces que retienen builds

Cada `result` de un `nix build` y cada `.direnv/` de un proyecto es una raíz: mientras
exista, lo que apunta no se borra.

```bash
find /nix/var/nix/gcroots/auto -type l -printf '%l\n' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
```

Un `~/result` olvidado retiene un sistema entero. Borrar el symlink y volver a correr `gc`.

## 3. Home — borrar NO libera (por un tiempo)

btrbk saca un snapshot de `@home` **cada hora** y retiene `24h 7d 4w 6m`
(`modules/btrbk.nix`). Un snapshot comparte bloques con el original (copy-on-write): un
archivo borrado sigue ocupando disco mientras algún snapshot lo tenga — **hasta 6 meses**.

- Limpiar home **ordena**, pero no es la palanca para espacio urgente.
- La contracara es buena: lo borrado se recupera (ver [rollback](rollback.md#un-archivo-borrado)).

Para liberar espacio de home YA, hay que podar snapshots, no archivos:

```bash
snap-ls                                   # listar snapshots
snap-dry                                  # qué haría btrbk
sudo btrbk -c /etc/btrbk/home.conf prune  # aplica la retención ahora
```

Si hace falta más, bajar la retención en `modules/btrbk.nix` + `rebuild` + `prune`.
Borrar un snapshot a mano (`btrfs subvolume delete`) funciona pero no tiene vuelta atrás.

### Lo que SÍ se libera en el acto (subvolúmenes fuera de los snapshots)

Un subvolumen anidado no entra en el snapshot del padre (btrfs no recursa). En este equipo lo son:

| Qué | Ruta | Cómo liberar |
|---|---|---|
| **Juegos de Steam** — la palanca más grande (531 G al 28-sep) | `~/.local/share/Steam/steamapps` | desinstalar desde Steam |
| Cachés | `~/.cache` | `nix shell nixpkgs#go -c go clean -cache` (Go), borrar la caché de la app que sea |

Ver cuánto ocupa cada juego:

```bash
for m in ~/.local/share/Steam/steamapps/appmanifest_*.acf; do
  n=$(sed -n 's/.*"name"\s*"\(.*\)"/\1/p' "$m"); d=$(sed -n 's/.*"installdir"\s*"\(.*\)"/\1/p' "$m")
  printf '%s\t%s\n' "$(du -sh ~/.local/share/Steam/steamapps/common/"$d" 2>/dev/null | cut -f1)" "$n"
done | sort -rh | head
```

Otras cachés que se regeneran, pero viven en `@home` (vuelven al disco cuando rotan los
snapshots): `~/.gradle/caches` (borrar con Gradle apagado; el próximo build de Android tarda más).

El journal ya está limitado a 1G (`services.journald.settings.Journal.SystemMaxUse` en
`modules/base.nix`): `journalctl --disk-usage` para verlo.

## 4. Por qué los números no coinciden

`/`, `/home` y `/nix` se montan con `compress=zstd:3`. `nix-collect-garbage` y `du` informan tamaño
**sin comprimir**; `df` mide el disco real. Medido el 28-sep-2026: el gc dijo
"17.9 GiB freed" y `df` bajó 10 G. No falta nada: es la misma cosa medida de dos formas.
La cifra que importa es la de `df`.

En home pasa igual: el 29-sep, borrar cachés que `du` medía en ~26 G y achicar el journal bajó `df`
3 G EN TOTAL (texto y caché de Go comprimen muchísimo; la parte de `.gradle` además quedó en los
snapshots). Un archivo ya comprimido (una `.iso`, un video) sí libera casi lo que dice `du`.
