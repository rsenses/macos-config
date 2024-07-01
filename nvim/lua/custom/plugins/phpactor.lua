-- PHP Refactoring Tools

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
    },
  },
  keys = {
    { '<Leader>cm', ':PhpActor context_menu<CR>', desc = 'PHPactor context [M]enu' },
  },
}
