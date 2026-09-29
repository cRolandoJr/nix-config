# El audio se distorsiona (chasquidos, sonido "roto")

Caso real (29-sep-2026): CS2 sonaba bien al principio y se distorsionaba después de un rato,
desde el menú. Otros juegos casi no.

## Cómo medirlo (mientras está sonando mal)

```bash
pw-top -b -n 3 > /tmp/pw.txt; grep '^R ' /tmp/pw.txt | awk '!seen[$2]++'
```

Cómo leerlo:

- La línea **sin `+`** es el **driver**: el nodo que marca el compás de todo el audio. Las que
  tienen `+` lo siguen. Lo normal es que el driver sea la SALIDA (el parlante o el HDMI).
- **`ERR`** = veces que un nodo no llegó a tiempo en su ciclo. Es un contador ACUMULADO desde que
  arrancó el nodo: lo que importa es si SUBE mientras suena mal (medir dos veces y restar).
- **`QUANT`** = tamaño del bloque. Chico (256 = 5,3 ms) es más sensible a picos de CPU.
- **`RATE`/`FORMAT`** de la app: si no es 48000, PipeWire la convierte (normal, pero suma trabajo).

Si tarda en aparecer, grabar una sesión entera y armar la línea de tiempo después:
`pw-top -b > /tmp/sesion.txt` (un bloque por segundo) mientras jugás; Ctrl+C al final.

## Lo que se encontró

1. El echo-cancel de Astro (`modules/audio.nix`) **abre el micrófono apenas suena cualquier
   cosa**, aunque no uses el micro ni Astro: necesita comparar lo que suena con lo que capta.
2. Los micrófonos tenían `priority.driver` 2000 y el parlante 1000 → el **micro pasaba a ser el
   driver** y el parlante seguía un reloj ajeno. Medido: micro de driver 900 de 912 segundos de
   CS2, y los `ERR` de CS2, parlante, micro y echo-cancel subiendo JUNTOS en ráfagas (una en el
   menú, otra justo cuando se oyó la distorsión).
3. Arreglo: regla `52-output-drives-graph` en `audio.nix` → las salidas ALSA con
   `priority.driver` 2500. Verificar:

```bash
pw-dump | jq -r '.[] | select(.info.props["node.name"]? // "" | test("^alsa_")) | "\(.info.props["priority.driver"]) \(.info.props["node.description"])"' | sort -rn
```

El parlante tiene que salir arriba (2500) y, con algo sonando, ser la línea sin `+` de `pw-top`.

## Si vuelve a pasar

- Medir con `pw-top` en el momento. Si el driver ya es la salida y los `ERR` suben igual, la causa
  que queda es la carga de CPU sobre un bloque chico (quantum 256). NO cambiado todavía, a propósito:
  un quantum más grande agrega latencia y solo se toca si esto se demuestra.
- Descartar Astro: su echo-cancel es lo que mantiene el micro abierto. Si Astro no se usa, sacar
  ese bloque de `audio.nix` elimina la causa de raíz (y el uso de CPU de PipeWire mientras suena algo).
- Reiniciar el audio sin reiniciar la PC: `systemctl --user restart pipewire pipewire-pulse wireplumber`
  (un rebuild NO reinicia estos servicios de usuario).
