-- Keybindings (binds.lua)
-- Todos llevan `description` (lo lee keybinds-viewer en SUPER+K).

local function app(cmd)
	return "uwsm app -- " .. cmd
end

local terminal = app("foot")
local float_terminal = app("foot --app-id=foot_float")
local FM2 = app("foot yazi")
local calendar = app("foot --app-id=foot_float ikhal")
local fileManager = app("thunar")
local browser = app("firefox")
local menu = app(
	"rofi -show combi -modes combi -combi-modes drun,window,calc "
		.. "-theme ~/.config/rofi/launcher.rasi"
)
local clipboard = "~/.config/hypr/scripts/cliphist_fuzzel.sh"
local wifi = "~/.config/rofi/wifi/wifi_manager.sh"

-- --- APLICACIONES Y MENÚS ---
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd(float_terminal), { description = "Terminal flotante" })
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "Navegador (firefox)" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(FM2), { description = "Archivos en terminal (yazi)" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(fileManager), { description = "Archivos GUI (thunar)" })
hl.bind(
	"SUPER + M",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/spotify-toggle.sh"),
	{ description = "Spotify: mostrar u ocultar" }
)
hl.bind(
    "SUPER + Tab", function()
    hl.plugin.hymission.toggle("forceall")
end, { description = "Vista general de ventanas y workspaces" })
hl.bind("SUPER + T", hl.dsp.exec_cmd(app("Telegram")), { description = "Telegram" })
hl.bind("SUPER + I", hl.dsp.exec_cmd(calendar), { description = "Calendario (ikhal)" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd(menu), { description = "Lanzador: apps, ventanas y calculadora" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("ryogami wallpaper ui"), { description = "Elegir wallpaper" })
hl.bind(
	"SUPER + SHIFT + W",
	hl.dsp.exec_cmd("ryogami wallpaper browse"),
	{ description = "Buscar wallpapers en Wallhaven" }
)
hl.bind("SUPER + C", hl.dsp.exec_cmd(clipboard), { description = "Historial de portapapeles" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh"), { description = "Bloquear pantalla" })
hl.bind("SUPER + A", hl.dsp.exec_cmd(wifi), { description = "Redes WiFi" })
hl.bind(
	"SUPER + K",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-viewer.sh"),
	{ description = "Ver estos keybinds" }
)

-- Activar a Astro por voz: escribe al FIFO que Astro lee (modo ASTRO_INPUT=hotkey). El `[ -p ]` escribe
-- SOLO si el FIFO existe (= Astro corriendo, que lo crea/borra) → si está apagado no crea un archivo
-- basura que rompería el próximo arranque. El timeout 0.3 es red por si Astro murió sucio (FIFO sin lector).
hl.bind(
	"SUPER + SHIFT + A",
	hl.dsp.exec_cmd([[[ -p /tmp/astro-trigger.fifo ] && timeout 0.3 bash -c 'echo go > /tmp/astro-trigger.fifo']]),
	{ description = "Astro: escuchá" }
)

-- Reload de waybar (config + style). Usar tras editar style.css o config.jsonc.
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("pkill -SIGUSR2 waybar"), { description = "Recargar waybar" })

-- --- GESTIÓN DE VENTANAS Y SISTEMA ---
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Cerrar ventana" })
hl.bind("SUPER + SHIFT + M", hl.dsp.exit(), { description = "Salir de Hyprland" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Pantalla completa" })
hl.bind("SUPER + V", function()
	local win = hl.get_active_window()
	local was_floating = win and win.floating
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	if win and not was_floating then
		hl.dispatch(hl.dsp.window.resize({ x = 1450, y = 800 }))
		hl.dispatch(hl.dsp.window.center())
	end
end, { description = "Alternar flotante (1450x800 y centrar)" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Alternar pseudo-tiling" })
hl.bind(
	"SUPER + CTRL + N",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-nightlight.sh"),
	{ description = "Night light: alternar (hyprsunset)" }
)
hl.bind("SUPER + grave", hl.dsp.exec_cmd("~/.config/hypr/scripts/hub-toggle.sh"), { description = "Hub dashboard" })

-- --- DWINDLE LAYOUT ---
-- togglesplit en 0.54+ va vía layoutmsg (ya no es dispatcher directo).
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Alternar split horizontal/vertical" })
hl.bind("SUPER + H", hl.dsp.layout("swapsplit"), { description = "Intercambiar ventanas del split actual" })
hl.bind("SUPER + O", hl.dsp.layout("movetoroot"), { description = "Promover ventana a nodo raiz" })

-- --- NOTIFICACIONES ---
hl.bind(
	"SUPER + N",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-dnd.sh"),
	{ description = "No molestar: alternar (mako)" }
)
hl.bind(
	"SUPER + SHIFT + N",
	hl.dsp.exec_cmd("makoctl dismiss --all"),
	{ description = "Descartar todas las notificaciones" }
)

-- --- EL SCRATCHPAD (Terminal Oculta) ---
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:magic" }),
	{ description = "Mandar ventana al scratchpad" }
)
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), { description = "Scratchpad: mostrar u ocultar" })

-- --- MOVIMIENTO DE FOCO (Flechas) ---
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }), { description = "Foco a la ventana de la izquierda" })
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }), { description = "Foco a la ventana de la derecha" })
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }), { description = "Foco a la ventana de arriba" })
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }), { description = "Foco a la ventana de abajo" })

-- --- MOVER VENTANA ENTRE MONITORES ---
hl.bind(
	"SUPER + SHIFT + Tab",
	hl.dsp.window.move({ monitor = "+1" }),
	{ description = "Mandar ventana al otro monitor" }
)

-- --- MOVER VENTANA EN EL WORKSPACE ACTUAL ---
hl.bind(
	"SUPER + SHIFT + left",
	hl.dsp.window.swap({ direction = "left" }),
	{ description = "Intercambiar ventana hacia la izquierda" }
)
hl.bind(
	"SUPER + SHIFT + right",
	hl.dsp.window.swap({ direction = "right" }),
	{ description = "Intercambiar ventana hacia la derecha" }
)
hl.bind(
	"SUPER + SHIFT + up",
	hl.dsp.window.swap({ direction = "up" }),
	{ description = "Intercambiar ventana hacia arriba" }
)
hl.bind(
	"SUPER + SHIFT + down",
	hl.dsp.window.swap({ direction = "down" }),
	{ description = "Intercambiar ventana hacia abajo" }
)

-- --- MODO REDIMENSIONAR (Submap) ---
-- SUPER+R entra, flechas ajustan, Escape sale.
-- OJO: no unificar la tecla de entrada con la de salida — hay un bug conocido
-- (#14733) donde la misma combinación no resetea desde adentro del submap.
hl.bind("SUPER + R", hl.dsp.submap("resize"), { description = "Modo redimensionar (flechas; Esc sale)" })

hl.define_submap("resize", function()
	hl.bind(
		"right",
		hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
		{ repeating = true, description = "Ensanchar 30px" }
	)
	hl.bind(
		"left",
		hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
		{ repeating = true, description = "Angostar 30px" }
	)
	hl.bind(
		"up",
		hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
		{ repeating = true, description = "Acortar 30px" }
	)
	hl.bind(
		"down",
		hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
		{ repeating = true, description = "Alargar 30px" }
	)
	hl.bind("escape", hl.dsp.submap("reset"), { description = "Salir del modo redimensionar" })
end)

-- Submap MOVE: mover ventana flotante con flechas (espejo del resize).
-- `moveactive` solo afecta a ventanas flotantes (foot_float, blueman, pavucontrol).
-- Para tiled, seguí usando SUPER+SHIFT+flecha (swap).
hl.bind("SUPER + G", hl.dsp.submap("move"), { description = "Modo mover ventana flotante (flechas; Esc sale)" })

hl.define_submap("move", function()
	hl.bind(
		"right",
		hl.dsp.window.move({ x = 30, y = 0, relative = true }),
		{ repeating = true, description = "Mover 30px a la derecha" }
	)
	hl.bind(
		"left",
		hl.dsp.window.move({ x = -30, y = 0, relative = true }),
		{ repeating = true, description = "Mover 30px a la izquierda" }
	)
	hl.bind(
		"up",
		hl.dsp.window.move({ x = 0, y = -30, relative = true }),
		{ repeating = true, description = "Mover 30px arriba" }
	)
	hl.bind(
		"down",
		hl.dsp.window.move({ x = 0, y = 30, relative = true }),
		{ repeating = true, description = "Mover 30px abajo" }
	)

	hl.bind(
		"SHIFT + right",
		hl.dsp.window.move({ x = 120, y = 0, relative = true }),
		{ repeating = true, description = "Mover 120px a la derecha (paso grande)" }
	)
	hl.bind(
		"SHIFT + left",
		hl.dsp.window.move({ x = -120, y = 0, relative = true }),
		{ repeating = true, description = "Mover 120px a la izquierda (paso grande)" }
	)
	hl.bind(
		"SHIFT + up",
		hl.dsp.window.move({ x = 0, y = -120, relative = true }),
		{ repeating = true, description = "Mover 120px arriba (paso grande)" }
	)
	hl.bind(
		"SHIFT + down",
		hl.dsp.window.move({ x = 0, y = 120, relative = true }),
		{ repeating = true, description = "Mover 120px abajo (paso grande)" }
	)

	hl.bind("escape", hl.dsp.submap("reset"), { description = "Salir del modo mover" })
end)

-- --- WORKSPACES (Escritorios Virtuales) ---
-- 20 binds mecánicos colapsados en un loop: mismo resultado, intención más clara.
-- i % 10 mapea el workspace 10 a la tecla 0, igual que el .conf.
for i = 1, 10 do
	local key = i % 10
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { description = "Ir al workspace " .. i })
	hl.bind(
		"SUPER + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Mandar ventana al workspace " .. i }
	)
end

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace siguiente (scroll)" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace anterior (scroll)" })

-- --- RATÓN (Mover y Redimensionar con clics) --- (eran bindm)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Arrastrar ventana con el mouse" })
hl.bind(
	"SUPER + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Redimensionar ventana con el mouse" }
)

-- --- HARDWARE (Volumen, Brillo, Multimedia) ---
-- swayosd-client hace la acción Y muestra el OSD. NO encadenar con wpctl:
-- ambos togglean → double-toggle (visible en mute como "luz prende y vuelve").
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-step.sh up osd"),
	{ repeating = true, description = "Subir volumen" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-step.sh down osd"),
	{ repeating = true, description = "Bajar volumen" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { description = "Silenciar" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { description = "Subir brillo" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { description = "Bajar brillo" })

hl.bind("xf86audionext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Pista siguiente" })
hl.bind(
	"xf86audioplay",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Reproducir o pausar" }
)
hl.bind("xf86audioprev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Pista anterior" })

-- --- CAPTURAS DE PANTALLA (HyprCapture) ---
hl.bind("Print", function()
	hl.plugin.hyprcapture.open("fullscreen")
end, { description = "Captura de pantalla completa (HyprCapture)" })

hl.bind("SUPER + SHIFT + C", function()
	hl.plugin.hyprcapture.open("region")
end, { description = "Captura de región (HyprCapture)" })

hl.bind("SUPER + CTRL + C", function()
	hl.plugin.hyprcapture.open_editor("region")
end, { description = "Captura de región y anotar (HyprCapture)" })

hl.bind("ALT + Print", function()
	hl.plugin.hyprcapture.record_toggle()
end, { description = "Grabar pantalla: iniciar o detener (HyprCapture)" })

-- --- MODO CLAMSHELL (Tapa de la laptop) ---
-- Si hay otro monitor conectado al cerrar la tapa, deshabilita eDP-1; al abrirla lo restaura.
hl.bind(
	"switch:on:Lid Switch",
	hl.dsp.exec_cmd([[sh -c '[ "$(hyprctl monitors | grep -c "^Monitor ")" -gt 1 ] && hyprctl keyword monitor "eDP-1,disable"']]),
	{ locked = true, description = "Clamshell: apagar eDP-1 al cerrar tapa si hay monitor externo" }
)
hl.bind(
	"switch:off:Lid Switch",
	hl.dsp.exec_cmd([[hyprctl keyword monitor "eDP-1,1920x1080@144,0x0,1"]]),
	{ locked = true, description = "Clamshell: reactivar eDP-1 al abrir tapa" }
)
