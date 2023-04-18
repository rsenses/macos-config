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
config.font = wezterm.font("SFMono Nerd Font")
config.font_size = 15.0
config.window_decorations = "RESIZE"
config.line_height = 1.1
config.audible_bell = "Disabled"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	left = 2,
	right = 2,
	top = 2,
	bottom = 0,
}
config.window_background_opacity = 0.95

-- For example, changing the color scheme:
config.color_scheme = "kanagawabones"

-- and finally, return the configuration to wezterm
return config
