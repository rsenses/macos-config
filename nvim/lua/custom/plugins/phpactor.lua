-- PHP Refactoring Tools
return {
  {
    'phpactor/phpactor',
    enable = false,
    event = 'VeryLazy',
    build = 'composer install --no-dev --optimize-autoloader',
    -- ft = 'php',
    keys = {
      {
        '<Leader>cpc',
        ':PhpactorCopyFile<CR>',
        desc = 'Copy file',
      },
      {
        '<Leader>cpi',
        ':PhpactorClassInflect<CR>',
        desc = 'Interface generation',
      },
      {
        '<Leader>cpm',
        ':PhpactorContextMenu<CR>',
        desc = 'Context menu',
      },
      {
        '<Leader>cpn',
        ':PhpactorClassNew<CR>',
        desc = 'New class',
      },
      {
        '<Leader>cpr',
        ':PhpactorMoveFile<CR>',
        desc = 'Move file',
      },
      {
        '<Leader>cpt',
        ':PhpactorTransform<CR>',
        desc = 'Implements contracts',
      },
    },
  },
  -- {
  --   'gbprod/phpactor.nvim',
  --   build = function()
  --     require 'phpactor.handler.update'()
  --   end,
  --   ft = { 'php' },
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'neovim/nvim-lspconfig',
  --   },
  --   opts = {
  --     install = {
  --      path = vim.fn.stdpath("data") .. "/mason/phpactor",
  --       bin = vim.fn.stdpath 'data' .. '/mason/bin/phpactor',
  --     },
  --     lspconfig = {
  --       enabled = false,
  --       options = {},
  --     },
  --   },
  --   keys = {
  --     {
  --       '<leader>cpm',
  --       function()
  --         require('phpactor').rpc('context_menu', {})
  --       end,
  --       desc = 'Open Context Menu',
  --     },
  --     {
  --       '<leader>ci',
  --       function()
  --         require('phpactor').rpc('import_class', {})
  --       end,
  --       desc = 'Import Class',
  --     },
  --   },
  --   config = true,
  -- },
}
