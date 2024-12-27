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
    return "NvimDark"
  else
    return "zenbones"
    -- return "NvimLight"
    -- return "dayfox"
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())

config.colors = {
  -- Overrides the cell background color when the current cell is occupied by the
  -- cursor and the cursor style is set to Block
  -- cursor_bg = "#14161b",
  -- Overrides the text color when the current cell is occupied by the cursor
  -- cursor_fg = "#eef1f8",
  -- Specifies the border color of the cursor when the cursor style is set to Block,
  -- or the color of the vertical or horizontal bar when the cursor style is set to
  -- Bar or Underline.
  -- cursor_border = "#14161b",

  -- Paleta de colores de nvimlight
  -- palette = 0=#07080d
  -- palette = 1=#590008
  -- palette = 2=#005523
  -- palette = 3=#6b5300
  -- palette = 4=#004c73
  -- palette = 5=#470045
  -- palette = 6=#007373
  -- palette = 7=#eef1f8
  -- palette = 8=#4f5258
  -- palette = 9=#590008
  -- palette = 10=#005523
  -- palette = 11=#6b5300
  -- palette = 12=#004c73
  -- palette = 13=#470045
  -- palette = 14=#007373
  -- palette = 15=#eef1f8
  -- background = #e0e2ea
  -- foreground = #14161b
  -- cursor-color = #9b9ea4
  -- selection-background = #9b9ea4
  -- selection-foreground = #14161b
}

config.font = wezterm.font("IosevkaTerm Nerd Font Mono")

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
config.send_composed_key_when_left_alt_is_pressed = true
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBlock"
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.default_prog = { "/opt/homebrew/bin/tmux" }

config.max_fps = 120
config.animation_fps = 120

-- and finally, return the configuration to wezterm
return config
