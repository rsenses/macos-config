-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "kanagawa (Gogh)"
config.font = wezterm.font("Terminess Nerd Font Mono")
config.font_size = 19
config.line_height = 1.2
config.window_padding = {
	left = 10,
	right = 0,
	top = 10,
	bottom = 0,
}
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.98
config.hide_tab_bar_if_only_one_tab = true
config.macos_window_background_blur = 10
config.send_composed_key_when_left_alt_is_pressed = true

-- and finally, return the configuration to wezterm
return config
