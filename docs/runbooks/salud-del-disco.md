# Salud del disco — ¿está sano?, y qué hacer si no

Un solo NVMe (`/dev/nvme0n1`) con LUKS y un filesystem btrfs montado en 7 lugares (`/`, `/home`,
`/nix`, `/var/log`…). Tres vigilancias automáticas, cada una ve una cosa distinta:

| Qué | Ve | Cuándo corre | Config |
|---|---|---|---|
| **SMART** (`smartd`) | el hardware: sectores, temperatura, desgaste | test corto diario 02:00, largo domingos 04:00 | `modules/smartd.nix` |
| **Scrub de btrfs** | los DATOS: lee todo y compara checksums | mensual (1.º de cada mes), prioridad idle | `modules/base.nix` |
| **Contadores de error de btrfs** | errores al leer o escribir | siempre, en cada acceso | (del kernel) |

Si algo falla, SMART avisa por notificación (mako). El scrub y los contadores no avisan solos:
se miran con los comandos de abajo.

## Mirada rápida (sin sudo)

```bash
cat /sys/fs/btrfs/*/devinfo/*/error_stats          # todo en 0 = ningún error DETECTADO
systemctl list-timers 'btrfs-scrub*'                # cuándo fue el último scrub y el próximo
journalctl -u 'btrfs-scrub@*' -n 20 --no-pager      # resultado del último scrub
journalctl -u smartd -b --no-pager | grep -iE 'fail|error|warn'   # vacío = bien
for h in /sys/class/hwmon/hwmon*; do [ -f $h/temp1_input ] && echo "$(cat $h/name) $(( $(cat $h/temp1_input) / 1000 ))°C"; done
```

**Ojo con el "todo en 0":** los contadores solo cuentan lo que se LEYÓ alguna vez. Un archivo
corrupto que nadie abre no aparece hasta que el scrub lo lee. Por eso el scrub existe: al 28-sep
el disco nunca había sido escaneado entero.

## Estado completo (con sudo)

```bash
sudo btrfs scrub status /           # último scrub: duración, datos leídos, errores
sudo smartctl -a /dev/nvme0n1        # SMART completo; mirar "Critical Warning", "Percentage Used", "Media and Data Integrity Errors"
```

## Correr un scrub a mano

```bash
sudo systemctl start btrfs-scrub@-.service     # el mismo que corre el timer; prioridad idle
sudo btrfs scrub status /                      # ver el progreso
```

Tarda del orden de una hora para lo que hay escrito (no medido todavía). Se puede seguir usando
la máquina. Conviene correr uno después de algo raro: un apagado forzado, un freeze, un error
de disco en el journal.

## Si aparecen errores

**Contador `corruption_errs` o scrub con errores de checksum:**

1. Ver QUÉ archivos: `sudo journalctl -k | grep -i 'checksum error'` nombra el inodo/ruta.
2. Con un solo disco, btrfs detecta la corrupción pero **no la puede reparar** (no hay una
   segunda copia): hay que restaurar ese archivo desde un respaldo.
   - En `~`: desde un snapshot, ver [rollback § archivo](rollback.md#un-archivo-borrado).
     **Revisar que el snapshot no tenga el mismo archivo corrupto**: uno anterior a la primera
     vez que apareció el error.
   - En `/nix/store`: se regenera. `sudo nix-store --verify --check-contents --repair`.
3. Correr otro scrub para confirmar que quedó limpio.

**Contadores `read_errs`/`write_errs`, o SMART avisa:** sospechar del hardware.

1. `sudo smartctl -a /dev/nvme0n1`: si "Media and Data Integrity Errors" o "Percentage Used"
   suben, el disco se está degradando.
2. **Respaldar YA lo que no está en git** a un disco externo ([disco-externo](../guias/disco-externo.md)):
   los snapshots viven en el MISMO disco y se pierden con él.
3. Recién después, diagnosticar.

## Por qué los números de espacio no coinciden

`/`, `/home` y `/nix` están montados con `compress=zstd:3`. `du` y las herramientas que borran
informan el tamaño SIN comprimir; el disco guarda menos. La única cifra real es `df -h /`.
Detalle en [disco-lleno](disco-lleno.md#4-por-qué-los-números-no-coinciden).
