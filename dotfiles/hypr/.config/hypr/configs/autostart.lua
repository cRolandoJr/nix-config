-- waybar, mako, ryogami y notify-layout corren como systemd user services.
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- eww daemon")
    hl.exec_cmd("uwsm app -- bash -c 'until eww ping >/dev/null 2>&1; do sleep 0.2; done; eww poll weather'")
    hl.exec_cmd("uwsm app -- swayosd-server")
    hl.exec_cmd("uwsm app -- hypridle -c ~/.config/hypr/hypridle.conf")
    hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
end)
