-- Autocompletion
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    'onsails/lspkind.nvim',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-git',
    {
      'L3MON4D3/LuaSnip',
      build = 'make install_jsregexp',
    },
    'saadparwaiz1/cmp_luasnip',
    'adoolaard/nvim-cmp-laravel',
    'zbirenbaum/copilot.lua',
    'zbirenbaum/copilot-cmp',
  },
  config = function()
    require('copilot').setup {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = false,
      },
    }

    require('copilot_cmp').setup()

    require 'custom.completion'
  end,
}
