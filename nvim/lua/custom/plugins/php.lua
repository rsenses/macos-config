return {
  'gbprod/phpactor.nvim',
  ft = 'php',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    -- you're options goes here
    -- install = { bin = vim.fn.stdpath 'data' .. '/mason/bin/phpactor' },
    lspconfig = {
      enabled = false,
    },
  },
  keys = {
    {
      'grm',
      function()
        require('phpactor').rpc('move_class', {})
      end,
      desc = 'Phpactor [M]ove',
    },
  },
}
