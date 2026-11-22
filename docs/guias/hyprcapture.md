# Mini manual de HyprCapture

Guía rápida de uso para **HyprCapture** en Hyprland (`hyprland.lua` + `binds.lua`).

## Atajos configurados

- **`Print`**: abre el modo **pantalla completa** (`fullscreen`). En la barra inferior podés elegir:
  - _Todos los monitores_ (`all`, por defecto)
  - _Monitor actual_ (`current`)
  - _Por monitor_ (`per-monitor`)
- **`SUPER + SHIFT + C`**: captura de **región solo al portapapeles** (no guarda archivo en disco, vía `hyprcapture-shot`).
- **`SUPER + CTRL + C`**: igual que el anterior, pero abre el **editor de anotaciones** antes de guardar y copiar.
- **`ALT + Print`**: inicia o detiene la **grabación** directamente (`record_toggle`).
- **`Esc`** (o clic derecho): cancela sin guardar.

Las capturas guardadas se almacenan en `~/Imágenes/Screenshots` (configurado en `hyprland.lua` con `plugin.hyprcapture.save_dir`).

## Editor de anotaciones (`SUPER + CTRL + C`)

### Herramientas

| Tecla       | Herramienta                                                           |
| ----------- | --------------------------------------------------------------------- |
| `V`         | Seleccionar / mover anotaciones                                       |
| `R`         | Rectángulo                                                            |
| `Shift + D` | Rectángulo relleno                                                    |
| `E`         | Elipse                                                                |
| `A`         | Flecha                                                                |
| `W`         | Línea                                                                 |
| `D`         | Lápiz                                                                 |
| `H`         | Resaltador                                                            |
| `T`         | Texto (`Enter` nueva línea, `Ctrl + Enter` confirmar, `Esc` cancelar) |
| `B`         | Marcador numerado                                                     |
| `G`         | Mosaico (pixelado)                                                    |
| `Shift + B` | Spotlight                                                             |

### Acciones y navegación

- **`Q`**: abrir paleta de colores
- **`Ctrl + Z`** / **`Z`**: deshacer
- **`Ctrl + Shift + Z`** / **`Ctrl + Y`** / **`X`**: rehacer
- **`Rueda del mouse`**: zoom alrededor del cursor
- **`Espacio + arrastrar`** (o clic medio): mover el lienzo
- **`Ctrl + 0`**: ajustar imagen a la pantalla
- **`P`** o **`Ctrl + P`**: **Pin** (fija la captura flotando en el escritorio; se cierra con `Esc` o su botón `×`)
- **`Enter`** o **`✓`**: confirmar (guarda en `~/Imágenes/Screenshots` y copia al portapapeles)

## Funciones extra

- **Scrolling screenshot (captura larga)**: en `SUPER + CTRL + C`, seleccioná una región o ventana y **scrolleá adentro**. Aparece una vista previa abajo a la derecha; al finalizar pasa al editor.
- **Grabación (video / GIF / WebP / APNG)**: abrí el overlay y tocá el ícono de **grabar** en la barra inferior. Para detener, volvé a abrir el overlay y tocá el mismo botón. Con `gpu-screen-recorder` instalado usa aceleración por GPU automáticamente en pantalla completa y región.
- **OCR**: dentro del editor podés seleccionar texto reconocido de la imagen o copiarlo con un clic (usa `tesseract` con soporte `eng` + `spa`).
- **Miniatura flotante**:
  - Clic izquierdo: abre la imagen guardada.
  - Arrastrar: suelta el archivo en otra aplicación.
  - **Swipe derecha**: cierra la miniatura.
  - **Swipe abajo**: borra el archivo y restaura el portapapeles anterior.
- **CLI**: `hyprcapture-shot [region|fullscreen|window] [-o PATH] [--editor]`.
