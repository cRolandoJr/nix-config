# Volver atrás — sistema, config o un archivo

## El sistema no arranca o quedó roto tras un rebuild

**Si no bootea:** en el menú de systemd-boot elegir una entrada anterior
("NixOS - Configuration N"). Hay hasta 20 (`configurationLimit` en `modules/boot.nix`),
siempre que el gc no las haya borrado — ver [disco lleno](disco-lleno.md#2-el-store-de-nix--se-libera-en-el-acto).

**Si bootea pero algo se rompió:**

```bash
nh os info                   # generaciones disponibles y cuál corre
nh os rollback               # vuelve a la anterior
```

El rollback cambia el sistema, **no el repo**: el flake sigue con el cambio que lo rompió.
Arreglarlo (o `git revert`) antes del próximo `rebuild`, o vuelve a romperse.

## Un update del flake rompió algo

```bash
cd ~/projects/nix-config
git log --oneline -- flake.lock | head   # el commit del update
git revert <commit>                      # vuelve al lock anterior
rebuild
```

Para retener un solo input viejo mientras se actualiza el resto, ver el pin de nixpkgs
documentado en [nixos-practica](../guias/nixos-practica.md).

## Un archivo borrado

Todo `~` tiene snapshots por hora (`modules/btrbk.nix`). Se leen sin sudo:

```bash
find /btrfs/@snapshots/home -maxdepth 1 -name '@home.*' | sort | tail -5
# ruta del archivo = /btrfs/@snapshots/home/@home.<fecha>/rolando/<ruta relativa a ~>
cp -n /btrfs/@snapshots/home/@home.20260928T2000/rolando/Descargas/archivo ~/Descargas/
```

Elegir el snapshot **anterior** al borrado. `cp -n` no pisa si el archivo ya volvió.
