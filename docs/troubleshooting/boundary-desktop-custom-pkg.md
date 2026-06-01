---
title: boundary-desktop empaquetado custom desde .deb oficial
status: resolved
date: 2026-05-29
nixpkgs: nixos-unstable @ 26.05.20260515.d233902
affected: pkgs/boundary-desktop.nix
tags: [electron, deb, hashicorp, setuid, zstd, autoPatchelfHook]
---

# boundary-desktop — empaquetar el .deb oficial en NixOS

`boundary-desktop` (cliente GUI de HashiCorp Boundary) no existe en nixpkgs, solo
el CLI/server `boundary`. Lo empaquetamos a mano desde el `.deb` que HashiCorp
publica en `releases.hashicorp.com`.

Probado con:
- boundary-desktop 2.6.0
- nixos-unstable @ 26.05.20260515.d233902
- AMD GPU (radeonsi), Wayland (Hyprland)

## Síntoma

Tres errores encadenados, en este orden, durante `nixos-rebuild`:

```
tar: ./usr/lib/boundary-desktop/chrome-sandbox: Cannot change mode to
  rwsr-xr-x: Operation not permitted
tar: Exiting with failure status due to previous errors
dpkg-deb: error: tar subprocess failed with exit status 2
```

```
tar (child): zstd: Cannot exec: No such file or directory
tar (child): Error is not recoverable: exiting now
```

```
Builder called die: Cannot wrap '.../opt/boundary-desktop/boundary-desktop'
because it is not an executable file
```

## Causa

Tres problemas independientes pero encadenados:

1. **setuid prohibido en `/nix/store`**. El `.deb` trae `chrome-sandbox`
   (parte de Electron) con permisos `rwsr-xr-x` (setuid root). Es un design
   choice de Nix: nada en el store puede ser setuid; los wrappers setuid se
   generan aparte en `/run/wrappers/bin/` vía `security.wrappers`. `dpkg-deb -x`
   intenta preservar el bit y el builder, que corre sin privilegios, lo rechaza.

2. **Compresión zstd en el `.deb`**. HashiCorp empezó a usar zstd en sus `.deb`
   recientes (mejor ratio que xz). `tar` detecta el formato pero invoca al
   binario `zstd` desde el `PATH`, y el stdenv mínimo solo trae `gzip` y `xz`.

3. **Path equivocado en el wrapper**. El `installPhase` original asumía que el
   binario vivía en `/opt/boundary-desktop/boundary-desktop` (patrón común en
   `.deb` propietarios). El `.deb` de boundary-desktop usa el layout estándar
   Debian: `/usr/bin/boundary-desktop` (symlink) → `/usr/lib/boundary-desktop/
   boundary-desktop` (binario Electron real, 203 MB).

## Fix

```nix
{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, zstd
, gtk3, glib, nss, nspr, atk, cups, libdrm, dbus, expat
, libx11, libxcomposite, libxdamage, libxext, libxfixes, libxrandr, libxcb
, mesa, alsa-lib, libpulseaudio, udev
}:

stdenv.mkDerivation rec {
  pname = "boundary-desktop";
  version = "2.6.0";

  src = fetchurl {
    url = "https://releases.hashicorp.com/boundary-desktop/${version}/boundary-desktop_${version}_amd64.deb";
    sha256 = "105p85gmx9n1w2jmqxijihm4pcwh51i7vv0i5x01i285vzj5nkpb";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper zstd ];

  buildInputs = [
    gtk3 glib nss nspr atk cups libdrm dbus expat
    libx11 libxcomposite libxdamage libxext libxfixes libxrandr libxcb
    mesa alsa-lib libpulseaudio udev
  ];

  unpackPhase = ''
    mkdir -p $out
    ar x $src
    tar -xf data.tar.* -C $out --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    mv $out/usr/* $out/
    rmdir $out/usr

    rm $out/bin/boundary-desktop
    makeWrapper $out/lib/boundary-desktop/boundary-desktop $out/bin/boundary-desktop \
      --add-flags "--no-sandbox" \
      --set NIXOS_OZONE_WL 1 \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland
  '';
}
```

Y en `home/rolando.nix` dentro de `home.packages`:

```nix
(callPackage ../pkgs/boundary-desktop.nix {})
```

## Por qué este fix

- **`ar x $src` + `tar --no-same-permissions --no-same-owner`** en vez de
  `dpkg-deb -x`. Un `.deb` es un archivo `ar` que contiene `control.tar.*` y
  `data.tar.*`. Extraer manualmente permite pasar los flags que ignoran el bit
  setuid. Es el patrón que usan Discord, Slack, etc. en nixpkgs.

- **`zstd` en `nativeBuildInputs`** porque `tar` lo invoca por nombre desde el
  `PATH` cuando detecta `.tar.zst`. Para `.tar.xz` o `.tar.gz` no haría falta.

- **`--add-flags "--no-sandbox"`** en el wrapper. Como no podemos tener
  `chrome-sandbox` con setuid en el store, Electron fallaría al inicializar su
  sandbox. La alternativa "más correcta" sería habilitar
  `security.chromiumSuidSandbox.enable = true;` global y exportar
  `CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chrome-sandbox`, pero es overkill para
  una app cliente que solo habla con el controller de Boundary (no renderiza
  web no confiable). Trade-off aceptado.

- **`rm $out/bin/boundary-desktop` antes del `makeWrapper`** porque el `.deb`
  ya crea ese path como symlink al binario en `lib/`. Sin el `rm`,
  `makeWrapper` falla con "Cannot wrap '...' because it is not an executable
  file" — el symlink lo confunde.

- **`libx*` en vez de `xorg.libX*`** porque el set `xorg.*` está deprecated en
  nixos-unstable desde mayo 2026. Funciona por alias pero tira warnings.

## Referencias

- https://releases.hashicorp.com/boundary-desktop/
- https://developer.hashicorp.com/boundary/docs/api-clients/desktop
- Patrón de `ar x` + `tar --no-same-permissions` para `.deb` con setuid:
  derivaciones de Discord, Slack, VSCode en nixpkgs
- Sobre setuid en `/nix/store`: módulo `security.wrappers` de NixOS
