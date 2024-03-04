return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      local focused = true
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          focused = true
        end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function()
          focused = false
        end,
      })
      table.insert(opts.routes, 1, {
        filter = {
          cond = function()
            return not focused
          end,
        },
        view = "notify_send",
        opts = { stop = false },
      })

      opts.commands = {
        all = {
          -- options for the message history that you get with `:Noice`
          view = "split",
          opts = { enter = true, format = "details" },
          filter = {},
        },
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.schedule(function()
            require("noice.text.markdown").keys(event.buf)
          end)
        end,
      })

      opts.presets.lsp_doc_border = true
    end,
  },
  -- buffer line
  -- {
  --   "akinsho/bufferline.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     options = {
  --       -- separator_style = "slant",
  --       show_buffer_close_icons = false,
  --       show_close_icon = false,
  --     },
  --   },
  -- },

  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function(_, opts)
      local logo = [[
oo__          _      _          __oo    ||     ·----·     ||
    """--,,,_(_)_--_(_)_,,,--"""        ||    /      \    ||
            _>_[____]_<_                ||=oo|        |oo=||
    ___--""" (_)\__/(_) """--___        ||    \      /    ||
oo""                            ""oo    ||     ·----·     ||
      ]]

      logo = string.rep("\n", 2) .. logo .. "\n\n"
      opts.config.header = vim.split(logo, "\n")
    end,
  },
}
