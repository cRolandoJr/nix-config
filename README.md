# nix-config

NixOS flake para HP Victus 16 (AMD Ryzen 5 7535HS + Radeon RX 6500M dGPU / 680M iGPU).

## Estructura

```
flake.nix               — inputs, outputs, devShell, pre-commit hooks
.sops.yaml              — reglas de cifrado (recipient age derivado de la SSH)
secrets/
  pedco.yaml            — TG_TOKEN + SECRET_KEY cifrados con sops
hosts/
  victus/
    default.nix         — imports de módulos + hostname + stateVersion
    disk.nix            — layout declarativo (disko): GPT + LUKS + btrfs 5 subvols
    hardware.nix        — módulos de kernel del initrd + microcódigo (sin UUIDs)
modules/
  base.nix              — locale, nix settings, usuario, sudo NOPASSWD, nix-ld, zram
  boot.nix              — systemd-boot, Plymouth, kernel params, consola silenciosa
  network.nix           — NetworkManager, Bluetooth, systemd-resolved, workarounds
  audio.nix             — Pipewire + rtkit
  fonts.nix             — Noto, JetBrainsMono, Nerd Fonts
  desktop-hyprland.nix  — Hyprland+UWSM, SDDM, XDG portals, polkit, notify-layout
  gpu-amd.nix           — amdgpu, RADV, LACT, variables VA-API/VDPAU
  gaming.nix            — Steam, gamescope, gamemode, ananicy-cpp, scx_lavd
  virtualisation.nix    — libvirt/KVM, virt-manager, Podman rootless
  btrbk.nix             — snapshots btrfs de @home cada hora (retención 24h/7d/4w/6m)
  k3s.nix               — cluster Kubernetes single-node local
home/
  rolando.nix           — home-manager: zsh, git, starship, fzf, dotfiles symlinks, paquetes,
                          systemd user services (pedco-bot: daemon + timer de avisos 8/20h)
pkgs/
  boundary-desktop.nix  — derivación custom de HashiCorp Boundary Desktop (no en nixpkgs)
```

## Instalación en una máquina nueva

El orden importa: **home-manager enlaza los dotfiles con `mkOutOfStoreSymlink`**, así que
si `~/projects/dotfiles` no existe al primer switch, la activación falla.

```bash
# ── 1. Desde el ISO de NixOS, particionar y formatear con disko.
#      OJO: esto BORRA el disco. Ajustar `device` en disk.nix si no es /dev/nvme0n1.
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake github:cRolandoJr/nix-config#victus

# ── 2. Instalar el sistema (disko ya dejó todo montado en /mnt).
sudo nixos-install --flake github:cRolandoJr/nix-config#victus

# ── 3. Reiniciar y entrar. Después, ANTES de cualquier rebuild:
mkdir -p ~/projects
git clone git@github.com:cRolandoJr/dotfiles.git   ~/projects/dotfiles
git clone git@github.com:cRolandoJr/nix-config.git ~/projects/nix-config

# ── 4. La SSH descifra los secretos: copiarla desde el backup.
#      Sin esto, pedco-bot no arranca (el resto del sistema sí).
install -m600 /ruta/al/backup/id_ed25519 ~/.ssh/id_ed25519

# ── 5. Ya se puede rebuildear normalmente.
cd ~/projects/nix-config && sudo nixos-rebuild switch --flake .#victus
```

### Pasos post-instalación

**Subvolúmenes anidados de churn pesado.** No están en `disk.nix` porque viven dentro de
`@home` y se crean recién cuando existe el home del usuario. Sin ellos, Steam y `~/.cache`
inflan los snapshots de btrbk hasta llenar el disco:

```bash
btrfs subvolume create ~/.cache
btrfs subvolume create ~/.local/share/Steam/steamapps
```

Runbook completo: `docs/2026-07-14-steam-subvolumen-migracion.md`.

**Lo que NO está en git** y hay que rehacer a mano: las VMs de libvirt
(`victim-01`, `wazuh-mgr`), las launch options de Steam, y la clave SSH del paso 4.

### Qué cambiar si el hardware es distinto

| Archivo | Qué revisar |
|---|---|
| `hosts/victus/disk.nix` | `device` — el único valor atado al disco |
| `hosts/victus/hardware.nix` | los módulos de `initrd.availableKernelModules` |
| `.sops.yaml` | agregar el recipient nuevo y `sops updatekeys secrets/pedco.yaml` |

Los `label` de las particiones (`ESP`, `primary`) están fijados en `disk.nix` a propósito:
disko los crea con esos nombres, así que los paths `/dev/disk/by-partlabel/…` resuelven
igual en cualquier máquina.

## Comandos frecuentes

```bash
# Rebuild y switch (usa nh, muestra diff pre/post)
rebuild                 # alias = nh os switch ~/projects/nix-config

# Variantes
rebuild-test            # activa config sin hacerla el default de boot
rebuild-boot            # la setea como default de boot sin activar ahora

# Actualizar inputs del flake
update                  # nix flake update

# Garbage collection
gc                      # nix-collect-garbage -d (user + system)

# Qué commit es la generación que estoy corriendo
nixos-version --configuration-revision
```

`system.configurationRevision` embute el commit en cada generación, así que el dato se
consulta desde adentro del sistema booteado. Reemplazó a la función `tag-gen`, que era
manual y solo llegó a cubrir 9 de 144 generaciones. Los tags `gen-*` viejos quedan como
historia.

## Devshell y pre-commit

Al entrar al directorio con direnv activo (`use flake` en `.envrc`), se instalan
automáticamente los hooks en `.git/hooks`:

- **nixfmt**: formatea todos los `.nix` (RFC 166).
- **statix**: lint de anti-patrones Nix.
- **deadnix**: detecta bindings sin uso.

Para instalarlos manualmente: `nix develop` o `nix flake check`.

## Dotfiles

Los dotfiles **no** viven en este repo. Están en `~/projects/dotfiles/` y se
enlazan como `mkOutOfStoreSymlink` desde home-manager. Para editar: modificar
el archivo en `~/projects/dotfiles/`, no el symlink en `~/.config/`.

Herramientas enlazadas: hypr, waybar, eww, cliphist, rofi, fastfetch, nvim, foot,
mako, khal, qt6ct, yazi, starship.

## Rollback

```bash
# Listar generations disponibles
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Volver a una generation anterior
sudo nixos-rebuild switch --rollback

# O elegir en el menú de systemd-boot al arrancar (configurationLimit = 20)
```

## Agregar un paquete

**User-level** (solo para rolando): agregar en `home/rolando.nix` → `home.packages`.

**System-level** (disponible para todos los usuarios / necesario para root):
agregar en el módulo correspondiente o en `modules/base.nix` → `environment.systemPackages`.

**Paquete custom** (no en nixpkgs): crear derivación en `pkgs/`, importar con
`callPackage ../pkgs/mi-pkg.nix { }` en `home.packages`.

## Notas de mantenimiento

- `hardware.nix` es autogenerado; los UUIDs son específicos de este disco.
- `system.stateVersion` y `home.stateVersion` no deben cambiarse después de instalar.
- Workarounds retirados: el `lib.mkForce` de bwrap (bubblewrap 0.11) ya no existe en
  `gaming.nix`, y el de blueman-applet nunca se aplicó — con UWSM el applet corre vía
  XDG-autostart y la unit systemd afectada queda sin uso (historia en `docs/notas.md` §8).
- `pedco-bot` (bot de Telegram) se declara en `home/rolando.nix` vía `inputs.pedco-bot`
  (GitHub pin de `cRolandoJr/scraper-pedco`). Para actualizar el bot: push a su `main`,
  luego `nix flake update pedco-bot` + `rebuild`. Los avisos 8/20h los dispara
  `pedco-bot-notify.timer` (`Persistent=true`, con catch-up tras suspend/apagado).
