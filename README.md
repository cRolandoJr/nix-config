# nix-config

NixOS flake para HP Victus 16 (AMD Ryzen 5 7535HS + Radeon RX 6500M dGPU / 680M iGPU).

## Estructura

```
flake.nix               — inputs, outputs, devShell, pre-commit hooks
hosts/
  victus/
    default.nix         — imports de módulos + hostname + stateVersion
    hardware.nix        — autogenerado nixos-generate-config (LUKS, btrfs, UUIDs)
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
