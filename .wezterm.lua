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
-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return "Dark"
end

function scheme_for_appearance(appearance)
    if appearance:find("Dark") then
        -- return "kanagawabones"
        -- return "zenbones_dark"
        -- return "melange_dark"
        return "Github Dark"
    else
        -- return "zenbones"
        -- return "melange_light"
        return "Github (base16)"
    end
end

config.color_scheme = scheme_for_appearance(get_appearance())

-- config.font = wezterm.font("IosevkaTerm Nerd Font Mono")
config.font = wezterm.font_with_fallback({
    "Iosevka Custom",
    { family = "Symbols Nerd Font Mono" },
})

config.font_size = 16
-- config.line_height = 1.1

-- default is true, has more "native" look
config.use_fancy_tab_bar = false

config.window_padding = {
    left = 10,
    right = 0,
    top = 5,
    bottom = 0,
}
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
-- config.window_background_opacity = 0.95
-- config.macos_window_background_blur = 10
config.send_composed_key_when_left_alt_is_pressed = true
config.automatically_reload_config = true

config.default_prog = { "/opt/homebrew/bin/tmux" }

-- and finally, return the configuration to wezterm
return config
