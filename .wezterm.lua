-- Pull in the wezterm API
local wezterm = require("wezterm")

local action = wezterm.action
local mux = wezterm.mux

local keys = {}

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.term = "xterm-256color"

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
-- config.window_close_confirmation = "NeverPrompt"
-- config.default_cursor_style = "BlinkingBlock"
-- config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
-- default is true, has more "native" look
config.use_fancy_tab_bar = false

-- config.default_prog = { "/opt/homebrew/bin/tmux" }

config.max_fps = 120
config.animation_fps = 120

-- keybindings
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

-- panes
table.insert(keys, { key = "-", mods = "LEADER", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) })
table.insert(keys, { key = "|", mods = "LEADER", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) })

-- local direction_keys = {
--   h = "Left",
--   j = "Down",
--   k = "Up",
--   l = "Right",
-- }

-- local function split_nav(key)
--   return {
--     key = key,
--     mods = "CTRL",
--     action = wezterm.action_callback(function(win, pane)
--       if pane:Get_users_vars().IS_NVIM == "true" then
--         -- pass the keys through to vim/nvim
--         win:perform_action({
--           SendKey = { key = key, mods = "CTRL" },
--         }, pane)
--       else
--         win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
--       end
--     end),
--   }
-- end

-- table.insert(keys, split_nav("h"))
-- table.insert(keys, split_nav("j"))
-- table.insert(keys, split_nav("k"))
-- table.insert(keys, split_nav("l"))

table.insert(keys, { key = "h", mods = "CTRL", action = action.ActivatePaneDirection("Left") })
table.insert(keys, { key = "j", mods = "CTRL", action = action.ActivatePaneDirection("Down") })
table.insert(keys, { key = "k", mods = "CTRL", action = action.ActivatePaneDirection("Up") })
table.insert(keys, { key = "l", mods = "CTRL", action = action.ActivatePaneDirection("Right") })

-- workspaces
wezterm.on("update-right-status", function(window, _)
  window:set_right_status(window:active_workspace())
end)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"
wezterm.on("gui-startup", function(_, args)
  local dotfiles_path = wezterm.home_dir .. "/dev/contrib/dotfiles/"
  mux.spawn_window({
    workspace = "dotfiles",
    cwd = dotfiles_path,
    args = args,
  })
  mux.set_active_workspace("dotfiles")
end)
table.insert(keys, { key = "s", mods = "LEADER", action = workspace_switcher.switch_workspace() })
table.insert(keys, { key = "f", mods = "CMD|SHIFT", action = action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) })
table.insert(keys, { key = "d", mods = "CMD|SHIFT", action = action.SwitchToWorkspace({ name = "dotfiles" }) })
table.insert(keys, { key = "[", mods = "CMD|SHIFT", action = action.SwitchWorkspaceRelative(1) })
table.insert(keys, { key = "]", mods = "CMD|SHIFT", action = action.SwitchWorkspaceRelative(-1) })

-- tabs
local function get_current_working_dir(tab)
  local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = "" }
  local HOME_DIR = string.format("file://%s", os.getenv("HOME"))

  return current_dir == HOME_DIR and "." or string.gsub(current_dir.file_path, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab)
  local has_unseen_output = false
  if not tab.is_active then
    for _, pane in ipairs(tab.panes) do
      if pane.has_unseen_output then
        has_unseen_output = true
        break
      end
    end
  end

  local cwd = wezterm.format({
    { Attribute = { Intensity = "Bold" } },
    { Text = get_current_working_dir(tab) },
  })

  local title = string.format(" [%s] %s", tab.tab_index + 1, cwd)

  if has_unseen_output then
    return {
      { Foreground = { Color = "#8866bb" } },
      { Text = title },
    }
  end

  return {
    { Text = title },
  }
end)

-- and finally, return the configuration to wezterm
config.keys = keys
return config
