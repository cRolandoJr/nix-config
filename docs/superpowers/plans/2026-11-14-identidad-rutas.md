# Identidad y rutas: diseño aprobado y plan

## Diseño

Centralizar username y hostname en personal.nix. Propagar argumentos a NixOS y
Home Manager; renombrar home/rolando.nix a home/user.nix. Derivar home y rutas
Android del usuario, y compartir una variable local para los enlaces a dotfiles.
Mantener los repositorios separados, sus ubicaciones y todos los valores efectivos.
Se descarta mover dotfiles ahora porque sería otra migración, no esta abstracción.

## Restricciones

Conservar el cambio previo que agrega xh. No actualizar flake.lock, activar el
sistema, construir paquetes, hacer commits ni publicar. No modificar secretos ni
discos. Ejecutar directamente el bloque aprobado, sin delegación.

## Plan y evidencia

- [x] Guardar baseline evaluado del árbol de trabajo, incluido xh.
- [x] Parametrizar flake, base, gaming, host y Home Manager; centralizar rutas.
- [x] Comparar derivación del sistema y valores efectivos antes/después con una
  revisión fija para que el estado dirty de Git no falsee la comparación.
- [x] Revisar diff, sintaxis y conservación de xh; documentar límites de prueba.

La identidad Git personal no se confunde con el usuario Unix. Conservar Rolando
como descripción de cuenta y la identidad Git configurada. La carpeta hosts/victus
sigue representando ese hardware. Las referencias históricas en guías se actualizarán
por separado; no reescribir registros de errores históricos como si fueran actuales.

## Resultado

Baseline y candidato producen exactamente la misma derivación del sistema al fijar
configurationRevision para la comparación. También coinciden usuario, grupos,
trusted-users, reglas sudo, variables, paquetes y archivos de Home Manager.
Se preservó xh. No se realizó build ni activación; flake.lock permanece intacto.

Archivos nuevos registrados con git add -N para que el flake Git los pueda leer;
no hay commit ni contenido staged. Las guías y el README apuntan ahora a home/user.nix. Solo se conserva
el nombre antiguo en el diseño del rename y en una salida histórica etiquetada.

Validación documental: nueve documentos actualizados pasan markdownlint con cero
errores. Se corrigieron errores de formato preexistentes en esos mismos archivos.
