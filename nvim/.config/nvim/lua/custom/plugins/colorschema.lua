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
    enabled = true,
    priority = 1000,
    config = function()
      vim.o.background = 'light'

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'LightGrey', bg = 'LightGrey' })
        end,
      })

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
    end,
  },
}
