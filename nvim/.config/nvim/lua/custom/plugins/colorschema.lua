return {
  {
    'zenbones-theme/zenbones.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    -- you can set set configuration options here
    config = function()
      vim.o.background = 'light'
      vim.g.zenbones_compat = 1
      vim.cmd.colorscheme 'zenbones'

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'LightGrey', bg = 'LightGrey' })
        end,
      })
    end,
  },
  {
    'webhooked/kanso.nvim',
    lazy = false,
    enabled = false,
    priority = 1000,
    config = function()
      vim.o.background = 'light'

      -- Default options:
      require('kanso').setup {
        commentStyle = { italic = true },
        functionStyle = { bold = true },
        keywordStyle = { bold = true },
        statementStyle = { bold = true },
        background = { -- map the value of 'background' option to a theme
          dark = 'ink', -- try "zen", "mist" or "pearl" !
          light = 'pearl', -- try "zen", "mist" or "pearl" !
        },
      }

      -- setup must be called before loading
      vim.cmd 'colorscheme kanso'

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'LightGrey', bg = 'LightGrey' })
        end,
      })
    end,
  },
  {
    'oskarnurm/koda.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    enabled = true,
    config = function()
      vim.o.background = 'light'

      require('koda').setup {
        transparent = true,

        -- Style to be applied to different syntax groups.
        -- Common use case would be to set either `italic = true` or `bold = true` for a desired group.
        -- See `:help nvim_set_hl` for more valid values.
        styles = {
          functions = { bold = true },
          keywords = {},
          comments = { italic = true },
          strings = { italic = true },
          constants = { bold = true },
        },

        -- Override colors
        -- These will be merged into the active palette (Dark or Light)
        -- Example colors for dark background:
        colors = {
          bg = '#FAF4ED',
          fg = '#2d3035',
          dim = '#ffffff',
          line = '#F8EFE5',
          comment = '#8E877F',
          border = '#2d3035',
          keyword = '#5A2E2A',
          emphasis = '#B4637A',
          func = '#33363c',
          const = '#356B6A',
          string = '#5F6B2D',
          highlight = '#6B4E2E',
          info = '#066E89',
          success = '#2F6B3F',
          warning = '#ff9f19',
          danger = '#e14e30',
        },
      }

      vim.cmd 'colorscheme koda'

      vim.api.nvim_set_hl(0, 'Visual', {
        bg = '#EEDFCF',
      })

      vim.api.nvim_set_hl(0, 'Pmenu', {
        bg = '#F4E7D9',
      })

      vim.api.nvim_set_hl(0, 'PmenuSel', {
        bg = '#D6D8C4',
        bold = true,
      })
    end,
  },
}
