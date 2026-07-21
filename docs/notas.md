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

---

## 7. Waybar + Hyprland — gotchas que costaron tiempo

### 7.1 Tilde (`~`) en `exec` de módulos custom NO se expande

Waybar 0.15 pasa el `exec` field a `popen()` sin shell expansion confiable.

**Síntoma**: el script funciona perfecto si lo invocás a mano, pero apenas waybar arranca via
`exec-once` de Hyprland tras un reboot, el custom module no se renderiza (silenciosamente, sin
error en logs).

**Regla**: **path absoluto siempre en cualquier `exec`/`exec-once` que apunte a un script**.

Mal:
```jsonc
"exec": "stdbuf -oL ~/.config/hypr/scripts/waybar-layout.sh"
```

Bien:
```jsonc
"exec": "stdbuf -oL /home/rolando/.config/hypr/scripts/waybar-layout.sh"
```

Hyprland sí expande `~` en `exec-once` (versiones recientes), así que ahí es opcional — pero por
consistencia uso paths absolutos en scripts.

### 7.2 Streaming custom modules necesitan `stdbuf -oL` o se traga el output

Cuando un script emite JSON continuo (waybar `return-type: "json"`), glibc usa **block-buffering
4KB** porque stdout no es un tty → la primera línea queda en buffer y waybar nunca recibe el primer
estado. El módulo aparece **vacío** o **clipea** a otra cosa.

Fix: `stdbuf -oL ./script.sh` fuerza line-buffering del stdout del proceso hijo.

### 7.3 Custom module suscrito al socket Hyprland — patrón

Patrón canónico para escuchar eventos Hyprland desde un script bash:

```bash
socat -U - "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" \
| while IFS= read -r line; do
    case "$line" in
      eventname\>\>*)
        payload="${line#*>>}"
        # ... procesar
        ;;
    esac
done
```

Eventos útiles: `activelayout`, `workspace`, `focusedmon`, `activewindow`, `submap`, `urgent`.

### 7.4 `SIGUSR2` (reload config) NO respawna procesos `exec` continuos

Si tocás un custom module con `exec` long-running y mandás `pkill -SIGUSR2 waybar`, la nueva config
se carga pero los procesos exec del módulo **siguen siendo los viejos**. Resultado: el cambio
parece no haber tenido efecto.

**Para custom modules con exec continuo: full restart** (`pkill waybar; setsid -f waybar`).

### 7.5 Cache de fontconfig corrupto rompe glyphs MDI selectivamente

**Síntoma**: algunos íconos Nerd Font aparecen, otros no — sin patrón obvio. Después de un rebuild
que actualiza la fuente, fontconfig cache queda desincronizado del store.

Fix:
```bash
rm -rf ~/.cache/fontconfig
fc-cache -fv
pkill waybar; setsid -f waybar
```

### 7.6 Strings de íconos en `format-icons` se pierden silenciosamente al editar

Si abrís `config.jsonc` en un editor que no maneja bien chars UTF-8 plane 15 (U+F0000-U+FFFFF),
los glyphs MDI se pueden **borrar silenciosamente** al guardar → el array queda
`["","","","",...]` con strings vacíos.

Para verificar:
```bash
python3 -c "
import json, re
text = open('/home/rolando/.config/waybar/config.jsonc').read()
clean = re.sub(r'//[^\n]*', '', text)
clean = re.sub(r'/\*.*?\*/', '', clean, flags=re.S)
data = json.loads(clean)
for mod in ('temperature','backlight','pulseaudio','battery'):
    print(mod, data.get(mod, {}).get('format-icons'))
"
```

Si los items son vacíos, restaurar con `chr(0xCODEPOINT)` directo en Python (no usar `\u` escapes
en heredocs bash — se rompen).

### 7.7 `time.timeZone` de NixOS != timezone que ve waybar

NixOS setea la zona del sistema vía `time.timeZone`. Pero waybar cuando se lanza fuera de
`exec-once` (ej: manualmente desde una terminal sin TZ propagada) puede usar UTC.

Fix robusto: declarar la zona **explícita en el módulo clock** del config:
```jsonc
"clock": {
  "timezone": "America/Argentina/Buenos_Aires",
  ...
}
```

Así es inmune a cómo se lance waybar.

### 7.8 Codepoints útiles MDI (Nerd Fonts 3.x)

Material Design Icons cambiaron de codepoints en Nerd Fonts 3.x. Los rangos vigentes:

| Símbolo | Codepoint | Glyph name |
|---|---|---|
| Termómetro empty | U+F2CB | fa-thermometer_empty (legacy FA, sigue funcionando) |
| Brightness 1-7 | U+F00DA → U+F00E0 | md-brightness_1 .. md-brightness_7 |
| Volume mute | U+F075F | md-volume_mute |
| Volume low/medium/high | U+F057F / U+F0580 / U+F057E | md-volume_low/medium/high |
| Battery 50% | U+F007E | md-battery_50 |
| Leaf | U+F032A | md-leaf |
| Rocket launch | U+F14DE | md-rocket_launch |
| Power settings | U+F0426 | md-power_settings |
| Clock | U+F0954 | md-clock |
| Memory | U+F035B | md-memory |
| WiFi strength | U+F091F → U+F0928 | md-wifi_strength_0 .. _4 |

Cómo encontrar nuevos:
```bash
nix-shell -p python3Packages.fonttools --run 'python3 -c "
from fontTools.ttLib import TTFont
f = TTFont(\"$(fc-match -f \"%{file}\" \"JetBrainsMono Nerd Font\")\")
for code, name in sorted(f.getBestCmap().items()):
    if \"BUSCAR\" in name.lower():
        print(f\"  U+{code:05X} → {name}\")"'
```

### 7.9 Reloj y zona horaria en autostart

El `exec-once` del autostart le pasa `env TZ=...` a waybar:
```
exec-once = env TZ=America/Argentina/Buenos_Aires waybar
```

Eso + el `"timezone"` explícito del módulo = doble defensa. No confiar solo en `time.timeZone`.

---

## 8. Bluetooth — `blueman-applet` con duplicate `ExecStart` (nixpkgs unstable)

> **Estado 2026-07-20:** el workaround nunca se aplicó en `network.nix` y ya no hace
> falta — con UWSM el applet corre vía XDG-autostart (`app-blueman@autostart.service`)
> y la unit systemd afectada queda sin uso (inactive, no failed). Sección conservada
> como referencia por si la unit vuelve a usarse.

### Síntoma

`services.blueman.enable = true;` deja el unit user en `bad-setting`:

```
blueman-applet.service: Service has more than one ExecStart= setting,
which is only allowed for Type=oneshot services. Refusing.
```

→ no hay tray icon, no hay notificaciones de pairing, `systemctl --user status
blueman-applet` muestra `Loaded: bad-setting`.

### Causa

El unit user upstream (`blueman-2.4.6/share/systemd/user/blueman-applet.service`)
trae `Type=dbus` + un `ExecStart=`. NixOS genera un drop-in
`.service.d/overrides.conf` que **suma** otro `ExecStart=` (sin resetearlo
antes con `ExecStart=` vacío). Systemd con `Type=dbus` permite solo uno → rechaza.

Visto en: nixos-unstable 26.05, build `2026-05-15` (`d233902`).
**Importante**: no es bug de tu config — viene de nixpkgs. Si upstream lo arregla,
este workaround se vuelve no-op y se puede borrar.

### Workaround — `modules/network.nix`

Mismo patrón que ya usamos para `bluetoothd` (resetear con `""` + redeclarar):

```nix
systemd.user.services.blueman-applet.serviceConfig.ExecStart = lib.mkForce [
  ""
  "${pkgs.blueman}/bin/blueman-applet"
];
```

Después del rebuild:

```bash
systemctl --user daemon-reload
systemctl --user restart blueman-applet
```

### Detalle ortogonal: el widget de waybar NO depende del applet

El módulo `"bluetooth"` de waybar habla directo a BlueZ por DBus. Si solo querés
el ícono en la barra (con click a `blueman-manager`), no necesitás el applet.
El applet agrega tray icon + notificaciones de pairing — opcional.

En `~/.config/waybar/config.jsonc` el módulo tiene que estar **listado en
`modules-right`**, no alcanza con definir el bloque (un día costó descubrirlo).
