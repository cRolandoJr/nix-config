# La laptop se colgó al suspender

Estado: **abierto sin causa**. Tres freezes (13, 17 y 21-jul-2026, kernel 7.1.1); ninguno
desde entonces. Revisado el 28-sep-2026: 0 en los últimos 60 boots (kernels 7.1.4 → 7.2.x).
Que no se repita **no prueba** que esté arreglado.

## ¿Fue este bug? — la firma

Después del reinicio forzado:

```bash
journalctl -b -1 -o short-precise | tail -20
```

| Mismo bug | Cierre normal |
|---|---|
| corta en seco en `Starting System Suspend...` | termina en `Journal stopped` |
| NO aparece `PM: suspend exit` | o en el cierre de la sesión de usuario |
| sin `/sys/fs/pstore` ni `/var/crash` (freeze duro, no panic) | |

## Ya descartado (no volver a mirar)

OOM, temperatura, errores de hardware (0 MCE), errores de GPU/DRM, cierre de tapa, y que
Steam abierto lo cause (suspendió bien con Steam en otros boots).

## Si vuelve

1. Anotar fecha, kernel (`uname -r`) y qué estaba abierto.
2. **Instrumentar con `pm_trace`**, pero primero resolver el reloj: `pm_trace` pisa el RTC
   y `systemd-timesyncd` sincroniza **una vez por boot**, así que los logs quedan con hora
   basura (pasó: 11h45m de atraso). Antes, agregar un unit `After=suspend.target` que
   resincronice NTP, o migrar a chrony.
3. Tras el freeze + reboot: `dmesg | grep -iE "magic number|hash matches"` nombra el device.

Sospechosos sin verificar: WiFi Realtek RTL8852BE (`rtw89_8852be`, tiene historial de
cuelgues s2idle en AMD) y la BIOS HP F.06 (oct-2024; `fwupd` no está instalado).
Otra herramienta en reserva: `amd_s2idle.py` (amd-debug-tools).

## Gotcha del instrumento

`timedatectl` falla siempre en este equipo (`Failed to read RTC`): `/dev/rtc` apunta a
`acpi-tad`, que no se puede leer. No indica reloj roto. El RTC real: `hwclock --rtc /dev/rtc1`.
