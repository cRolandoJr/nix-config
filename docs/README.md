# Docs — manual de operación de victus

Tres tipos de documento, cada dato en **un solo lugar**:

- **guias/** — cómo se usa algo (referencia y práctica).
- **runbooks/** — "pasó X, hacé Y". Solo de incidentes que ya ocurrieron.
- **troubleshooting/** — un problema resuelto, con causa y por qué del fix
  (plantilla: `troubleshooting/_template.md`).

Los comandos del día a día viven en [nix-cheatsheet](guias/nix-cheatsheet.md). Si otro
documento los necesita, enlaza ahí en vez de copiarlos: una copia se desactualiza sola.

## Si pasa…

| Pasa | Ir a |
|---|---|
| Me quedo sin disco | [runbooks/disco-lleno](runbooks/disco-lleno.md) |
| El rebuild falla o no aplicó mi cambio | [runbooks/rebuild-falla](runbooks/rebuild-falla.md) |
| Un rebuild o update rompió algo / no bootea | [runbooks/rollback](runbooks/rollback.md) |
| Borré un archivo de `~` | [runbooks/rollback § archivo](runbooks/rollback.md#un-archivo-borrado) |
| Se colgó al suspender | [runbooks/freeze-suspend](runbooks/freeze-suspend.md) |
| Quiero instalar / declarar algo nuevo | [guias/nixos-practica](guias/nixos-practica.md) |
| No me acuerdo de un comando | [guias/nix-cheatsheet](guias/nix-cheatsheet.md) |
| Conectar el disco externo y copiar | [guias/disco-externo](guias/disco-externo.md) |
| Commit con identidad personal vs trabajo | [guias/git-identidades](guias/git-identidades.md) |
| Atajos de nvim / yazi | [guias/nvim](guias/nvim.md) · [guias/yazi](guias/yazi.md) |
| Espejar el celular (scrcpy) | [scrcpy-hyprland-arch](scrcpy-hyprland-arch.md) |
| Por qué Steam tiene su subvolumen | [2026-07-14-steam-subvolumen-migracion](2026-07-14-steam-subvolumen-migracion.md) |
| boundary-desktop no abre | [troubleshooting/boundary-desktop-custom-pkg](troubleshooting/boundary-desktop-custom-pkg.md) |
| Por qué un flag de gaming, Flutter/ADB, gotchas de waybar | [notas](notas.md) |

Instalar en una máquina nueva: [README del repo](../README.md#instalación-en-una-máquina-nueva).
