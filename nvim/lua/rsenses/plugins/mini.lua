
return {
  'echasnovski/mini.nvim',
  version = '*',
  dependencies = {
    {
      'echasnovski/mini.splitjoin',
      version = false
    },
    'lewis6991/gitsigns.nvim',
  },
  config = function()
    require('mini.comment').setup()
    require('mini.pairs').setup()
    require('mini.splitjoin').setup()
    require('mini.statusline').setup()
    require('mini.surround').setup()
    require('gitsigns').setup()
  end,
}
