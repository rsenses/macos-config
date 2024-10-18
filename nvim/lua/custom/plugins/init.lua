return {
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('gitsigns').setup({})
  -- {
  --   'jwalton512/vim-blade',
  --   enabled = false,
  -- },
  'tpope/vim-repeat',
  {
    'folke/ts-comments.nvim',
    opts = {
      lang = {
        blade = '{{-- %s --}}',
        html = '{{-- %s --}}',
      },
    },
    event = 'VeryLazy',
    enabled = vim.fn.has 'nvim-0.10.0' == 1,
  },
}
