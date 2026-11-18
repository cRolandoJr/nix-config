#!/usr/bin/env bash
# Ajusta el volumen al múltiplo de 5 más cercano (0..150).
set -euo pipefail

vol=$(pamixer --get-volume)
case "${1:-}" in
  up)
    next=$(( (vol / 5 + 1) * 5 ))
    (( next > 150 )) && next=150
    ;;
  down)
    if (( vol % 5 == 0 )); then
      next=$(( vol - 5 ))
    else
      next=$(( (vol / 5) * 5 ))
    fi
    (( next < 0 )) && next=0
    ;;
  *)
    exit 1
    ;;
esac

pamixer --allow-boost --set-volume "$next"
if [[ "${2:-}" == "osd" ]]; then
  swayosd-client --output-volume 0 --max-volume 150 >/dev/null 2>&1 || true
fi

