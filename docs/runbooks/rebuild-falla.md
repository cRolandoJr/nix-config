# El rebuild falla (o no hizo lo que creía)

Primero ubicar **en qué fase** falló: nh lo muestra. Evaluar → construir → activar son
tres fallas distintas, con arreglos distintos.

## 0. ¿Cambió el sistema de verdad?

Ver "builds ✔" no significa que el sistema se activó. Evidencia:

```bash
nixos-version --configuration-revision   # commit de la generación que corre
git -C ~/projects/nix-config rev-parse HEAD
readlink /run/current-system             # store path activo
```

Si la revisión termina en `-dirty`, rebuildeaste con cambios sin commitear: funciona, pero
perdés el vínculo exacto generación ↔ commit. Commitear antes de `rebuild`.

## 1. "No existe el path" o el cambio no se aplica — archivo nuevo sin `git add`

Un flake copia al store **solo lo que git conoce**. Un `.nix` nuevo en estado `??` es
invisible: el rebuild dice que no existe, o peor, usa la versión anterior y parece que tu
`.nix` está mal.

```bash
git status --short          # ?? pkgs/foo.nix  ← el flake NO lo ve
git add pkgs/foo.nix        # alcanza con stagear, no hace falta commitear
```

Agregar por nombre, no `git add -A` (barre todo lo untracked).

## 2. Falla la activación después de un update de kernel — `scx.service` SIGSEGV

Firma: `nh os switch` sale con **exit 4 en la fase `test`**; `scx.service` crashea en
`OpenBpfSkel::load`. El build está bien.

Causa: el `scx_lavd` nuevo está compilado contra el kernel **nuevo**, pero el switch no
cambia el kernel en vivo; el scheduler BPF carga contra el kernel viejo y revienta. Además
esa corrida **no registró** la generación de boot.

```bash
rebuild-boot                # registra la generación sin activarla en vivo
reboot
```

Regla: `flake update` o cambios de kernel/Mesa/GPU → `rebuild-boot` + reboot, no `rebuild`.

## 3. Un paquete no compila después de `update`

```bash
cd ~/projects/nix-config
nix build .#nixosConfigurations.victus.pkgs.<paquete> -L   # aislarlo, con log
```

Leer el error del **paquete que falla**, no el final del log. Casos reales:
`lact` (una lib subió de versión mayor) y `ananicy-cpp` (`fmt` 12.2 dejó de incluir
headers: `no type named 'int32_t' in namespace 'std'`).

Salidas, de menor a mayor costo:

1. **Esperar**: revertir el lock (`git checkout flake.lock`) y probar en unos días.
   Si Hydra ya lo arregló, `nix build github:NixOS/nixpkgs/nixos-unstable#<paquete>`
   baja del caché en vez de compilar.
2. **Override** del paquete: `pkg.override { dep = <versión vieja>; }`.
3. **Pin de nixpkgs** a un rev anterior. Ver [nixos-practica](../guias/nixos-practica.md).

## 4. `update` "no trae nada"

Un nixpkgs pinneado a un **rev fijo** no se mueve con `nix flake update`, y no avisa.

```bash
grep -n 'nixpkgs.url' flake.nix   # debe ser .../nixos-unstable, no un hash
```

Si hay pin, tiene que tener comentario con el motivo y el gatillo para levantarlo.

## 5. `sudo: a terminal is required to read the password`

`rebuild` es `nh`, y `nh` no está en el sudo sin clave (`modules/base.nix`, allowlist).
Desde tu terminal pide la clave y listo. Si corre desde algo sin terminal (un script, un
agente), el build termina pero **la activación no**: usar
`sudo nixos-rebuild switch --flake ~/projects/nix-config#victus`, que sí está en la lista.
