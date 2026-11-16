#!/usr/bin/env bash
# Modo juego: para k3s. NO toca el perfil de energía: gamemode ya pone el governor en
# performance por juego, y powerprofilesctl necesita un polkit que un click no tiene.

UNITS=(k3s.service)
SYSTEMCTL=/run/current-system/sw/bin/systemctl
ICON="<span size='12pt'>󰊴</span>"

# `is-active` devuelve "inactive" tanto si el unit está parado como si NO EXISTE,
# así que no alcanza para decidir. `is-enabled` sí distingue (da "not-found").
exists() { [ "$(systemctl is-enabled "$1" 2>/dev/null)" != "not-found" ]; }

# Estado del conjunto: si alguno corre, el modo juego está OFF.
state() {
  local any_exists=0 any_active=0 u
  for u in "${UNITS[@]}"; do
    exists "$u" || continue
    any_exists=1
    [ "$(systemctl is-active "$u" 2>/dev/null)" = active ] && any_active=1
  done
  if [ "$any_exists" = 0 ]; then
    echo absent
  elif [ "$any_active" = 1 ]; then
    echo running
  else
    echo stopped
  fi
}

emit() {
  case "$(state)" in
    running)
      printf '{"text":"%s","class":"off","tooltip":"Modo juego OFF\\nk3s corriendo\\nClick para detenerlo"}\n' "$ICON"
      ;;
    stopped)
      printf '{"text":"%s","class":"on","tooltip":"Modo juego ON\\nk3s parado\\nClick para volver a arrancarlo"}\n' "$ICON"
      ;;
    absent)
      printf '{"text":"%s","class":"absent","tooltip":"k3s no está declarado en esta config\\nNada que togglear"}\n' "$ICON"
      ;;
  esac
}

case "${1:-status}" in
  toggle)
    case "$(state)" in
      absent)
        notify-send -u low -a "Modo juego" "Nada que togglear" \
          "k3s no está declarado en esta config."
        exit 0
        ;;
      running) action=stop ;;
      stopped) action=start ;;
    esac

    done_units=()
    for u in "${UNITS[@]}"; do
      exists "$u" || continue
      sudo "$SYSTEMCTL" "$action" "$u" && done_units+=("${u%.service}")
    done

    if [ "$action" = stop ]; then
      notify-send -a "Modo juego" -i input-gaming \
        "Modo juego ON" "Parados: ${done_units[*]:-nada}"
    else
      notify-send -a "Modo juego" -i input-gaming \
        "Modo juego OFF" "De vuelta: ${done_units[*]:-nada}"
    fi
    pkill -RTMIN+11 waybar 2>/dev/null || true
    ;;
  *)
    emit
    ;;
esac
