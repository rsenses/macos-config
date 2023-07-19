return {
  -- or you can return new options to override all the defaults
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      local icons = require("lazyvim.config").icons
      local Util = require("lazyvim.util")

      return {
        -- options = {
        --   theme = "base16",
        -- },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
          },
          lualine_x = {
            { require("lazy.status").updates, cond = require("lazy.status").has_updates, color = Util.fg("Special") },
            {
              "diff",
              colored = true, -- Displays a colored diff status if set to true
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
      }
    end,
  },
}
