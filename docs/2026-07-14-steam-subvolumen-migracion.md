# Migración: Steam a subvolumen btrfs (excluido de snapshots)

**Fecha:** 2026-07-14 · **Host:** victus

## Problema (evidencia)

Disco de 1TB al 100% (61M libres). Causa raíz confirmada, no duplicados:

- `@home` se snapshotea **cada hora** con btrbk (`modules/btrbk.nix`, retención 24h/7d/4w/6m).
- Dentro de `@home` vive `~/.local/share/Steam` (~371G de juegos) como **carpeta normal**.
- Steam reescribe bloques todo el tiempo (parches, shadercache, descargas). Con btrfs copy-on-write,
  cada bloque reescrito deja el viejo **anclado por el snapshot** aunque el archivo actual ya no lo use.
- Sobre 371G de datos calientes × ~26 snapshots → cientos de GB de bloques huérfanos-pero-retenidos,
  invisibles a `du` (que solo ve el árbol actual, no los bloques retenidos por versiones pasadas).

Medición por descarte: `df` usado 928G − "vivo" (`du`) ~546G = **~382G retenidos por snapshots**.
Verificado que el nix store NO es el culpable (`nix store gc --dry-run` = 4 paths muertos).

## Fix canónico

El problema no es "muchos juegos", es **mezclar datos calientes-y-reemplazables (juegos, nube) con
datos importantes-y-livianos (dotfiles, docs, configs) en el mismo subvolumen snapshoteado**.

Solución estructural (patrón Snapper/openSUSE, Arch wiki): **la librería de Steam es un subvolumen
anidado propio**. Un subvolumen hijo NO entra en el snapshot del padre (btrfs no recursa) → aparece
como carpeta vacía en cada snapshot de `@home` → **auto-excluido, sin tocar `btrbk.nix`**.

Como se decidió **borrar todos los juegos** (re-descargables desde Steam), la conversión es gratis:
no hay que copiar 371G, solo crear el subvolumen vacío donde Steam re-bajará a demanda.

## Estado previo (2026-07-14)

- Ya se borraron 15 snapshots viejos (25-may a 13-jul) → recuperó ~190G (100% → 80%, 192G libres).
- Quedan 11 snapshots de hoy (IDs 795-805, 08:27–18:13) que aún anclan el Steam actual.
- `btrbk-home.timer` detenido durante la cirugía.
- Juegos a borrar: RDR2 120G, Darktide 97G, CS2 65G, The Division 50G, BLOODSTRIKE 26G.

## Runbook

### Checkpoint 1 — liberar espacio (borrar snapshots de hoy)

Los 11 snapshots de hoy anclan la churn de hoy (~186G). Borrarlos libera eso y **desancla** los
juegos para que el paso 2 los libere de verdad. Costo: se pierde rollback a estados de HOY (mitigado:
código en git; btrbk se reactiva al final y toma snapshots nuevos enseguida).

→ `sudo bash del-today-snapshots.sh` · esperado: ~385G libres, 0 snapshots.

### Checkpoint 2 — reestructurar y borrar juegos

1. Steam cerrado (verificar `pgrep -x steam`).
2. `mv steamapps → steamapps.old` (rename instantáneo en `@home`).
3. `btrfs subvolume create steamapps` + `chown rolando:users`.
4. Preservar `libraryfolders.vdf` (registro de librería) en el subvolumen nuevo.
5. `rm -rf steamapps.old` → libera ~360G (ya desanclados).
6. `systemctl start btrbk-home.timer` (reactivar snapshots).

→ `sudo bash migrate-steam-subvol.sh` · esperado: ~745G libres, `steamapps` es subvolumen.

### Verificación

- `btrfs subvolume show ~/.local/share/Steam/steamapps` → confirma que es subvolumen.
- Abrir Steam → librería vacía, re-login OK, re-descargar juegos a demanda.
- Próximo snapshot btrbk: `~/.local/share/Steam/steamapps` aparece **vacío** dentro del snapshot.

## Declarativo / persistencia

- **No requiere cambios en `btrbk.nix`** (el subvolumen anidado se auto-excluye).
- El subvolumen es data en disco: **persiste entre `nixos-rebuild`**. Solo una reinstalación limpia
  lo perdería → por eso queda documentado acá.
- Consistente con el setup actual (los subvolúmenes se crean al instalar, no vía Nix). Un systemd
  oneshot solo-para-Steam sería incoherente y especulativo. Migrar a `disko` = scope aparte.

## `~/.cache` también excluido (2026-07-14)

Mismo patrón: `~/.cache` (~18G, regenerable) convertido a subvolumen anidado y excluido de los
snapshots. Snapshotear un cache es puro costo sin valor (se regenera solo). Contenido preservado
(no se borró). Verificado con archivo-testigo.

## Nota futura (diferida, con gatillo)

Otros dirs de dev dentro de `@home` (`~/.gradle` 7.5G, `~/Android` 5.8G, `~/.local/share/containers`
2.3G podman) también se snapshotean. Hoy son chicos y acotados por la retención — NO justifican
subvolumen (regla: no especular). **Gatillo:** si alguno crece e infla los snapshots, mismo patrón.
`~/work` (código gama23) SÍ se deja en snapshots a propósito: protege trabajo no commiteado.
