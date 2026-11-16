# Licencias y atribuciones

# Nota de alcance

Este archivo documenta la procedencia y las licencias de componentes de terceros
incluidos en esta configuración personal. No aplica una licencia MIT general
al conjunto del repositorio. Las fuentes de terceros conservan sus licencias
y avisos originales.

## Componentes incorporados

- **Daemon Ryogami (Go, GPL-3.0):** código reutilizado y adaptado desde
  [Ryoku-dev/ryoku](https://github.com/Ryoku-dev/ryoku), en
  `ryoku/shell/ryogami/daemon/`. Se conserva una copia completa de la
  [GPL-3.0 del upstream](../pkgs/ryogami/daemon/LICENSE) y del
  [NOTICE histórico](../pkgs/ryogami/UPSTREAM_NOTICE) de la revisión
  [41d7e5b](https://github.com/Ryoku-dev/ryoku/tree/41d7e5b92ce9e6d0bd2b5d79ec0396e49c003fc6).
  En esa revisión, 55 de los 148 archivos del paquete vendorizado coinciden
  byte a byte con el upstream (incluidos 13 del daemon); otros contienen
  adaptaciones locales o proceden de distintas revisiones. El código del daemon
  conserva la licencia GPL-3.0: **la licencia MIT de los archivos propios del
  starter no lo relicencia**. Para revisar modificaciones, comparar el
  directorio local con ese commit y el historial Git de este repositorio.
- **Selector Ryogami (QML, MIT):** procede del selector
  [skwd-wall de liixini](https://github.com/liixini/skwd-wall), que Ryoku
  integró como `wall-ui` en
  [5d7e520](https://github.com/Ryoku-dev/ryoku/commit/5d7e5201c34138d6ee3862f2819e89af6e65a364)
  y eliminó del upstream en
  [9c20a71](https://github.com/Ryoku-dev/ryoku/commit/9c20a712283e750ac96812c9a350b3300fc867e9).
  Se conserva [LICENSE del selector](../pkgs/ryogami/wall-ui/LICENSE),
  copyright (c) 2026 liixini. Las modificaciones para integrarlo a Ryogami
  no cambian los derechos ni la autoría del código de origen.
- **Procedencia dentro de los repos propios:** los 148 archivos rastreados
  bajo `pkgs/ryogami/` antes de añadir estas licencias coinciden por SHA de
  blob con el árbol de
  [nix-config en 1053d0c](https://github.com/cRolandoJr/nix-config/tree/1053d0c4b0c4504594c923f727f444fc9986e560).
  Ese cotejo establece la ruta de copia entre repositorios del mismo usuario,
  **no atribuye autoría original** del daemon ni del selector a ese usuario.
  Por su parte, comparados con la revisión `41d7e5b` de Ryoku, los 148
  archivos se distribuyen en 55 idénticos, 88 distintos en contenido y 5
  inexistentes con la misma ruta en esa revisión.

La comparación de blobs indicada arriba cubre los archivos compartidos con el
starter; no supone que el conjunto del repositorio personal tenga esa misma
historia de modificaciones o que el resto de dotfiles tenga licencia uniforme.

