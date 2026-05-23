# Notas — fixes y decisiones de diseño

Este doc captura decisiones no obvias del config y workarounds que llevó tiempo descubrir.
Si futuro-yo se pregunta "¿por qué está esto así?", la respuesta está acá.

---

## 1. Flutter mobile dev en NixOS (proyecto gama23)

### Problema

El equipo (no-NixOS) usa FVM con Flutter 3.35.7 pinned. El repo declara en
`.vscode/settings.json` (versionado):

```json
"dart.flutterSdkPath": ".fvm/versions/3.35.7"
```

En NixOS los binarios que descarga FVM no corren (FHS — esperan `/lib/ld-linux-x86-64.so.2`),
y modificar el `settings.json` del equipo deja diff permanente en el repo.

### Solución: shim local con symlink

**Devshell local-only** en `~/work/gama23/.nix-shells/mobile/flake.nix` (repo sin remoto):

1. `buildInputs` incluye `pkgs.flutter335` (versión exacta del equipo).
2. El `shellHook` crea un symlink local al nix-store:

   ```bash
   FVM_LINK="/home/rolando/work/gama23/gama23_mobile_front/.fvm/versions/3.35.7"
   ln -sfn "${pkgs.flutter335}" "$FVM_LINK"
   ```

3. `.fvm/` está gitignored → el symlink **nunca sale al remoto**.
4. El `dart.flutterSdkPath` del equipo resuelve a algo válido en ambos lados.

### Versión de NDK — ojo

Flutter hardcodea la versión de NDK en
`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt::ndkVersion`.

Para Flutter 3.35.7 → **NDK `27.0.12077973`**.

Si el `ndkVersions` del flake no coincide con esa constante, Gradle intenta descargar
la versión correcta al `$ANDROID_SDK_ROOT` (que es `/nix/store/...` → **read-only**) y el
build muere con `SDK directory is not writable`.

**Cuando el equipo bumpee Flutter, abrir `FlutterExtension.kt` de la versión nueva y
actualizar `ndkVersions` en el flake.**

### Versiones de buildTools / platformVersions

El flake lista varias por las dudas (`36.0.0 35.0.0 34.0.0 28.0.3` para buildTools,
`36 35 34 33 31` para platforms). Si el proyecto bumpea AGP/compileSdk, agregar la
versión necesaria. El `GRADLE_OPTS` con `aapt2FromMavenOverride` apunta a una versión
concreta — si Gradle se queja de aapt2, alinear ese path a la buildTools que use el
proyecto (`android/app/build.gradle`).

### Estado del repo del equipo

**Cero diff vs upstream.** Verificación:

```bash
cd ~/work/gama23/gama23_mobile_front
git diff HEAD -- .vscode/ android/local.properties
# debe ser vacío
```

---

## 2. ADB en NixOS systemd 258+ (NO usar `programs.adb`)

### Lo que NO va más

```nix
# DEPRECADO desde nixpkgs PR #454366 — rompe el build:
programs.adb.enable = true;
users.users.<u>.extraGroups = [ "adbusers" ];  # el grupo no existe
```

Error que tira si lo agregás:

```
The option definition `programs.adb' [...] no longer has any effect; please remove it.
This option is no longer needed as systemd 258 handles uaccess rules automatically.
```

### Lo que sí va (NixOS ≥ con systemd 258)

Solo instalar el paquete:

```nix
home.packages = [ pkgs.android-tools ];   # ya está en home/rolando.nix
```

**systemd uaccess** maneja los permisos USB automáticamente — basado en sesión local
de logind, no en grupo. `android-udev-rules` y el grupo `adbusers` fueron removidos en
paralelo.

### Verificación

```bash
adb devices   # tiene que listar el cel sin sudo, sin estar en ningún grupo especial
```

---

## 3. Tunings de gaming / performance — el "por qué" de cada flag

### `RADV_PERFTEST = "gpl"` (sin `nosam`) — `modules/gpu-amd.nix`

- `gpl` = Graphics Pipeline Library (compilación de shaders más rápida).
- `nosam` **deshabilitaba Smart Access Memory** (Resizable BAR). En kernel ≥ 7 con RADV
  reciente, SAM se activa automáticamente y rinde +5-15% en GPU-bound. **No volver a
  agregar `nosam` salvo regresión específica.**

### `vm.swappiness = 180` + tunings zram — `modules/base.nix`

zramSwap está enabled con `memoryPercent = 50` → 15 GB de RAM comprimida zstd.
Con `swappiness=1` el kernel **casi nunca usa zram** → desperdicio.

Configuración recomendada por kernel docs para sistemas con zram:

```nix
"vm.swappiness" = 180;             # usar zram agresivamente
"vm.page-cluster" = 0;             # zram = random access, sin read-ahead
"vm.watermark_boost_factor" = 0;
"vm.watermark_scale_factor" = 125;
```

### `transparent_hugepage=madvise` — `modules/base.nix`

Con `always`, el kernel hace compactación global para armar hugepages → produce
**stutter ocasional en juegos**. Con `madvise`, sólo se asignan hugepages cuando una
app lo pide explícitamente (jemalloc, juegos modernos compilados así lo hacen).
Trade-off: menos hugepage coverage en otras workloads, pero gaming es la prioridad.

### `services.ananicy` con `ananicy-rules-cachyos` — `modules/gaming.nix`

ananicy-cpp da `nice`/`ionice` automático por categoría de proceso (juego = high prio,
indexer/backup = low prio). Las reglas de CachyOS son un set curado y mantenido.
Impacto: ~3-8% en CPU-bound games con muchos procesos compitiendo.

### `services.scx` con `scx_lavd` — `modules/gaming.nix`

sched-ext (mainline desde kernel 6.12) permite cargar schedulers en userspace vía BPF.
`scx_lavd` es latency-aware — mejor input lag en gaming con multitasking.

**Failure mode benigno**: si el daemon crashea, kernel cae a EEVDF default sin reboot.
Para rollback temporal sin tocar nada: `sudo systemctl stop scx`.

Si en el futuro algo se siente raro bajo carga: probar `scx_bpfland` (más conservador).

### Bluetooth `controllerMode = "dual"` — `modules/network.nix`

`"le"` deshabilita Bluetooth Classic (BR/EDR) → audífonos A2DP/aptX no funcionan.
`"dual"` habilita ambos modos (clásico + BLE).

### `vm.max_map_count = 2147483642` — `modules/gaming.nix`

Star Citizen, Hogwarts Legacy y otros juegos modernos lo piden. Sin esto crashean al
inicio con "could not mmap". Es el valor estándar que recomiendan Steam y CachyOS.

---

## 4. Decisiones que NO son optimizaciones — heredadas

- **`amdgpu.dcdebugmask=0x10`**: **NO agregar**. Es flag de debug del display core,
  no de performance (lo había en algún tutorial viejo). Solo agrega overhead.
- **`programs.adb.enable`**: **NO agregar** (ver sección 2).

---

## 5. Comandos de utilidad

```bash
# Rebuild del sistema
rebuild              # alias: sudo nixos-rebuild switch --flake ~/projects/nix-config#victus
rebuild-test         # prueba sin generar nueva entrada de boot
rebuild-boot         # activa después del próximo reboot, no ahora

# Mantenimiento
update               # nix flake update en este repo
gc                   # garbage-collect del store

# Diagnóstico
nix flake check      # validar que evalúa
systemctl is-active scx ananicy   # verificar daemons de gaming
```

---

## 6. Si algún día se rompe Flutter en gama23

Checklist en orden:

1. `direnv allow` en `~/work/gama23/gama23_mobile_front/` (autorización expirada o `.envrc` cambió).
2. Salir y reentrar al devshell para refrescar `ANDROID_SDK_ROOT` si cambió el store path.
3. `rm -rf ~/work/gama23/gama23_mobile_front/{android/.gradle,.dart_tool,android/local.properties}`.
4. Verificar que `ls .fvm/versions/3.35.7/bin/flutter` resuelve al nix-store actual.
5. Verificar que el `ndkVersion` del flake matchea `FlutterExtension.kt` de la versión actual de Flutter.
6. En VSCode: `Ctrl+Shift+P` → "Developer: Reload Window".
