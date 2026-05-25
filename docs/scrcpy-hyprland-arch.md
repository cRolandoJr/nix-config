# scrcpy en Hyprland — perfil sin stutter y con mouse usable

Notas para alguien usando **Arch + Hyprland + Wayland** (también aplica a NixOS y a
cualquier distro con SDL3). Probado con:

- scrcpy 4.0 (SDL 3.4.2, libavcodec 62)
- Hyprland sobre Wayland
- AMD Radeon (decode H.264 vía VAAPI/radeonsi)
- Monitor 144 Hz
- Android 13 (cualquier device con SDK ≥ 28 que soporte UHID)

## TL;DR

Lanzá scrcpy con estos flags:

```bash
scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl
```

Si querés que ese sea el comportamiento default cuando tipeás `scrcpy`, agregá un
alias a `~/.zshrc` (o `~/.bashrc`):

```bash
alias scrcpy='scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl'
```

Reabrí la terminal. **Bonus**: el `.desktop` upstream de scrcpy ya hace
`Exec=/bin/sh -c "$SHELL -i -c scrcpy"` — lanza un shell interactivo, así que el
alias también se aplica cuando lanzás desde rofi/wofi/anyrun.

---

## Por qué cada flag

### `--mouse=uhid`

El default `--mouse=sdk` re-mapea botones del mouse a acciones de Android:
right-click = BACK, middle-click = HOME, click-4 = APP_SWITCH, click-5 = notif.
Es útil si querés controlar Android "como Android", pero confuso si lo usás como
PC normal.

`uhid` simula un mouse físico USB-HID vía el módulo del kernel `uhid`. Todos los
clicks van directos como clicks reales — el Android lo ve como un mouse enchufado.
Scroll y drag más naturales. Algunas apps Android que detectan "mouse físico"
mejoran la UI.

**Trade-off**: el cursor del host se "captura" dentro de la ventana de scrcpy
(modo relative pointer). Para soltarlo: tappear el MOD (ver siguiente flag).

### `--shortcut-mod=lsuper`

El MOD default es **Alt o Super**. Si tu Hyprland (o tu setup de teclado) tiene
algo como `grp:alt_shift_toggle` para cambiar layouts, una pulsación de Alt suelta
podría interferir mentalmente. Forzando `lsuper` (solo Super izquierdo),
descomprimís: Super es solo "Windows key", queda libre de chocar con bindings de
teclado típicos.

Atajos relevantes con MOD = Super:

- `Super` (tap solo, sin combo) → soltar/recapturar el cursor
- `Super+b` → BACK
- `Super+h` → HOME
- `Super+s` → APP_SWITCH
- `Super+q` → quit scrcpy

### `--no-audio`

Quita el forward de audio del celu a la PC. Razones:

- scrcpy sincroniza video con audio → si no necesitás audio, sacarlo **elimina
  una fuente grande de jitter percibido**.
- Reduce CPU y bandwidth USB.

Si querés audio del celu en la PC, omití este flag — pero entonces aceptás más
latencia. Alternativa: mantenelo y usá Bluetooth del celu para el audio aparte.

### `--max-fps=60`

Sin este flag, el celu puede grabar a 60 fps mientras tu monitor refresca a 144 Hz.
El frame pacing entre ambos no encaja y scrcpy interpola/duplica frames de forma
irregular → **stutter percibido aunque el FPS promedio sea alto**.

Fijar el cap en 60 hace que el pipeline tenga cadencia uniforme. Si tu monitor
es 60 Hz, igual va bien (cap = refresh). Si tenés un device gaming a 120 Hz nativo
y monitor a 144 Hz, podés probar `--max-fps=120`.

### `--render-driver=opengl`

**Este flag es la clave si tenés Hyprland + SDL3.** SDL3 en Wayland a veces elige
un render driver default (Vulkan o software) que stuttea o no usa GPU eficiente.
Forzar `opengl` da un path predecible y estable.

Síntoma típico sin este flag: `--print-fps` muestra dips frecuentes a 16-30 fps
con muchos `+N frames skipped`, aunque tu CPU/GPU esté tranquilo.

---

## Cómo verificar que está OK

Lanzá con `--print-fps`:

```bash
scrcpy <flags> --print-fps
```

Mientras tocás/scrolleás el celu, en la terminal vas a ver:

```
INFO: 60 fps
INFO: 60 fps
INFO: 58 fps
INFO: 60 fps
```

Estable cerca de 60, con dips ocasionales chiquitos. **Las rachas de `0 fps`
cuando no tocás nada son normales y deseadas** — el encoder de Android para de
generar frames si la pantalla no cambia (ahorra batería). No es lag.

Si seguís viendo dips grandes (a 15-30 fps con `frames skipped`) y tu CPU/GPU no
está saturado, escala:

1. Agregá `--max-size=1600` (reduce resolución de decode sin afectar nitidez
   visible para una ventana mediana).
2. Probá `--video-codec=h265` (mejor compresión, decoder hw a veces más rápido;
   requiere que tu device Android lo soporte como encoder, casi todos los
   modernos sí).
3. Verificá VAAPI en tu GPU: `vainfo | grep -i h264` debería listar perfiles
   con `VAEntrypointVLD`. Si no aparece, instalá los drivers VAAPI de tu GPU
   (en Arch: `libva-mesa-driver` para AMD/Intel libres, `libva-nvidia-driver`
   para nvidia).

---

## Persistencia — opciones por shell

**zsh**: alias en `~/.zshrc` (ver TL;DR).

**bash**: igual pero en `~/.bashrc`.

**fish**:

```fish
alias scrcpy='scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl'
funcsave scrcpy
```

**Wrapper en `~/.local/bin/`** (alternativa shell-agnostic, sirve también si
algún launcher no lanza shell interactivo):

```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/scrcpy <<'EOF'
#!/bin/sh
exec /usr/bin/scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl "$@"
EOF
chmod +x ~/.local/bin/scrcpy
```

Asegurate que `~/.local/bin` esté antes que `/usr/bin` en `$PATH`. El `"$@"` te
deja agregar flags adicionales en cada invocación si necesitás (ej. `scrcpy --record foo.mp4`).

---

## Gotchas

- **Cursor capturado se siente raro al principio**: si tenés dos monitores y
  movés el mouse de un lado al otro constantemente, el toggle con Super va a
  cansar. Workaround: dejar scrcpy en un workspace dedicado de Hyprland; no
  necesitás sacar el mouse.

- **UHID requiere `uhid` kernel module**. En Arch viene en el kernel default
  desde hace años; no hay que tocar nada. Para verificar:
  `lsmod | grep uhid` o `modprobe uhid && ls /dev/uhid`.

- **USB 2.0 alcanza**: 480 Mbps cabe los ~8 Mbps default de scrcpy sin
  problema. USB 3.0 no mejora nada perceptible salvo que subas bitrate.

- **Si usás `adb tcpip` (WiFi)** en vez de cable: agregá `--video-bit-rate=4M`
  para no saturar el WiFi y bajar jitter.

- **Pantalla del celu vertical (1080×2400 típico)**: scrcpy escala a la ventana
  automáticamente. Si querés rotar a horizontal: `--rotation=1` o `Super+←/→`
  en vivo.

---

## Comandos full de referencia

**Uso normal (cable USB, monitor 144 Hz, sin audio)**:

```bash
scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl
```

**Grabando a archivo**:

```bash
scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 \
       --render-driver=opengl --record=screen.mkv
```

**WiFi (adb tcpip)**:

```bash
scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 \
       --render-driver=opengl --video-bit-rate=4M
```

**Solo mirror (sin control)** — útil para demos sin mouse capture:

```bash
scrcpy --no-audio --max-fps=60 --render-driver=opengl --no-control
```
