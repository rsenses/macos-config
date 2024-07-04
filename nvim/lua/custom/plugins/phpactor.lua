return {
  'gbprod/phpactor.nvim',
  build = function()
    require 'phpactor.handler.update'()
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'neovim/nvim-lspconfig',
  },
  opts = {
    install = {
      path = vim.fn.stdpath 'data' .. '/mason/phpactor',
      bin = vim.fn.stdpath 'data' .. '/mason/bin/phpactor',
      -- path = vim.fn.expand '~/dev/contrib/phpactor',
      -- bin = vim.fn.expand '~/dev/contrib/phpactor/bin/phpactor',
    },
  },
  cond = vim.fn.isdirectory 'vendor' == 1,
  keys = {
    { '<Leader>cm', ':PhpActor context_menu<CR>', desc = 'PHPactor context [M]enu' },
  },
}
