-- PHP Refactoring Tools
return {
  'phpactor/phpactor',
  event = 'VeryLazy',
  build = 'composer install --no-dev --optimize-autoloader',
  ft = 'php',
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
}
-- return {
--   'gbprod/phpactor.nvim',
--   ft = { 'php' },
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'neovim/nvim-lspconfig',
--   },
--   opts = {
--     install = {
--       bin = vim.fn.stdpath 'data' .. '/mason/bin/phpactor',
--     },
--     lspconfig = {
--       enabled = false,
--       options = {},
--     },
--   },
--   keys = {
--     {
--       '<leader>cm',
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
-- }
