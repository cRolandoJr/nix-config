#!/usr/bin/env bash
# lock.sh — Lanza hyprlock con shader de viñeta

SHADER="$HOME/.config/hypr/shaders/lock-vignette.glsl"

if [[ ! -f "$SHADER" ]]; then
    exec hyprlock
fi

trap 'hyprctl keyword decoration:screen_shader ""' EXIT
hyprctl keyword decoration:screen_shader "$SHADER"
hyprlock
