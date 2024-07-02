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
      path = vim.fn.expand '~/dev/contrib/phpactor',
      bin = vim.fn.expand '~/dev/contrib/phpactor/bin/phpactor',
      check_on_startup = 'daily',
    },
  },
  keys = {
    { '<Leader>cm', ':PhpActor context_menu<CR>', desc = 'PHPactor context [M]enu' },
  },
}
