-- Hyprland · Deep Ocean
-- Validar: Hyprland --config ~/.config/hypr/hyprland.lua --verify-config
hl.plugin.load(os.getenv("HOME") .. "/.local/lib/hyprland/libhymission.so")
hl.plugin.load(os.getenv("HOME") .. "/.local/lib/hyprland/libhyprcapture.so")
hl.plugin.load(os.getenv("HOME") .. "/.local/lib/hyprland/libhyprfocus.so")
hl.plugin.load(os.getenv("HOME") .. "/.local/lib/hyprland/libhyprbars.so")

hl.config({
	plugin = {
		hyprfocus = {
			keyboard_focus_animation = "flash",
			mouse_focus_animation = "flash",
			fade_opacity = 0.85,
		},
		hyprbars = {
			enabled = true,
			bar_height = 24,
			bar_color = "rgb(0f172a)",
			col = {
				text = "rgb(e2e8f0)",
			},
			bar_text_size = 11,
			bar_part_of_window = true,
			bar_precedence_over_border = false,
			bar_padding = 10,
			bar_button_padding = 6,
		},
	},
})
require("configs.environments")
require("configs.monitors")
require("configs.settings")
require("configs.autostart")
require("configs.rules")
require("configs.workspaces")
require("configs.binds")

-- deadlocked_overlay no_blur windowrule
hl.window_rule({
    match = {
        title = "^(deadlocked_overlay)$",
    },
    no_blur = true,
})
