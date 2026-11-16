# nix-config

NixOS flake para HP Victus 16 (AMD Ryzen 5 7535HS + Radeon RX 6500M dGPU / 680M iGPU).

## Estructura

```text
flake.nix               — inputs, outputs, devShell, pre-commit hooks
personal.nix            — username y hostname, consumidos por el flake
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
  gaming.nix            — Steam, gamescope, gamemode, ananicy-cpp
  virtualisation.nix    — libvirt/KVM, virt-manager, Podman rootless
  btrbk.nix             — snapshots btrfs de @home cada hora (retención 24h/7d/4w/6m)
  k3s.nix               — cluster Kubernetes single-node local
home/
  user.nix              — home-manager: zsh, git, starship, fzf, dotfiles symlinks, paquetes,
                          systemd user services (pedco-bot: daemon + timer de avisos 8/20h)
dotfiles/               — configuraciones editables y Wallpapers/
pkgs/
  hymission/            — plugin de vista general, construido contra nuestro Hyprland
  boundary-desktop.nix  — derivación custom de HashiCorp Boundary Desktop (no en nixpkgs)
```

## Identidad y rutas

`personal.nix` declara `username = "rolando"` y `hostname = "victus"`.
El flake pasa esos valores a los módulos mediante `specialArgs`; Home Manager
recibe `username` mediante `extraSpecialArgs`. El módulo de usuario es
`home/user.nix`, cuyo nombre no depende del login.

El home se deriva de `username`. En `home/user.nix`, `dotfilesDir` centraliza
`${config.home.homeDirectory}/projects/nix-config/dotfiles` para los enlaces externos.
Los wallpapers viven en `dotfiles/Wallpapers/`. Las rutas Android también se derivan del home.
El sistema, los dotfiles y los wallpapers se mantienen en este único repositorio.

`hostname` selecciona el output y `hosts/${hostname}`: cambiarlo exige mantener
coherente la carpeta del host. Cambiar `username` no migra archivos, permisos ni
credenciales de una cuenta existente; esta abstracción conserva los valores actuales.
La identidad Git y la descripción personal de la cuenta son datos distintos del login.

## Instalación en una máquina nueva

El orden importa: **home-manager enlaza los dotfiles con `mkOutOfStoreSymlink`**, así que
el checkout local debe existir en `~/projects/nix-config`, con su carpeta `dotfiles/`,
antes de activar sus enlaces. El código descargado al store por el flake no sustituye ese checkout.

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

`rebuild`, `update`, `gc`, generaciones y demás: [docs/guias/nix-cheatsheet](docs/guias/nix-cheatsheet.md)
(única copia). Índice de guías y runbooks: [docs/](docs/README.md).

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

Los dotfiles viven en `dotfiles/` dentro de este repo. Home Manager los enlaza
mediante `mkOutOfStoreSymlink`. Editar el origen en `~/projects/nix-config/dotfiles/`.
Los cambios de contenido requieren la recarga propia de la aplicación; cambiar los
enlaces o paquetes requiere construir y activar la configuración.

Los wallpapers se seleccionan y descargan en `dotfiles/Wallpapers/`.
`hymission` se carga desde el enlace que gestiona Home Manager; `Super + Tab`
alterna la vista general de ventanas y workspaces.

Los dotfiles permanecen fuera del store: un rollback de generación no revierte
sus ediciones. Para recuperar su contenido se usa Git o el respaldo correspondiente.

Herramientas enlazadas: hypr, waybar, eww, cliphist, rofi, fastfetch, nvim, foot,
mako, khal, qt6ct, yazi, starship.

## Rollback

Sistema, update del flake o un archivo borrado: [docs/runbooks/rollback](docs/runbooks/rollback.md).

## Agregar un paquete

**User-level** (solo para rolando): agregar en `home/user.nix` → `home.packages`.

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
- `pedco-bot` (bot de Telegram) se declara en `home/user.nix` vía `inputs.pedco-bot`
  (GitHub pin de `cRolandoJr/scraper-pedco`). Para actualizar el bot: push a su `main`,
  luego `nix flake update pedco-bot` + `rebuild`. Los avisos 8/20h los dispara
  `pedco-bot-notify.timer` (`Persistent=true`, con catch-up tras suspend/apagado).
