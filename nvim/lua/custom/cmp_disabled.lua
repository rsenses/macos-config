-- Autocompletion
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  enable = false,
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    'onsails/lspkind.nvim',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-git',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'adoolaard/nvim-cmp-laravel',
    'zbirenbaum/copilot.lua',
    'zbirenbaum/copilot-cmp',
  },
  config = function()
    require 'custom.completion'
  end,
}
