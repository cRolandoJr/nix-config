---
title: {título corto, mismo que el H1}
status: resolved | workaround | wontfix | superseded
date: {YYYY-MM-DD del fix}
nixpkgs: {nixos-unstable @ commit-corto o fecha del result symlink}
affected: {ruta del archivo / nombre del paquete / módulo afectado}
tags: [{lista corta de keywords para grep: electron, deb, systemd, wayland, ...}]
---

# {Título descriptivo — qué pasó y qué se hizo}

Probado con:
- {versión del paquete / herramienta}
- {versión de NixOS, ej: nixos-unstable @ 26.05.20260515}
- {otros componentes relevantes: kernel, hardware, etc.}

## Síntoma

{Mensaje de error literal copy-pasted, o descripción del comportamiento.
Esto es lo que vas a googlear/grepear en 6 meses cuando vuelva a pasar.}

```
{error como aparece en el terminal/journalctl}
```

## Causa

{Por qué pasa, idealmente el root cause real, no solo "no funciona". Si hay
varias capas (ej: tres errores encadenados), enumerá.}

## Fix

{El cambio concreto. Que se pueda copiar y pegar.}

```nix
{snippet o diff}
```

## Por qué este fix

{El razonamiento. Qué hace cada parte, qué trade-offs aceptás, qué alternativas
descartaste y por qué. Esta sección es la que te enseña — sin ella el doc es solo
un comando que no entendés.}

## Referencias

- {issues, PRs de nixpkgs, docs upstream, threads de discourse, etc.}
