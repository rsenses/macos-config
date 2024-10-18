return {
  'ThePrimeagen/refactoring.nvim',
  keys = {
    {
      '<leader>rr',
      function()
        require('telescope').extensions.refactoring.refactors()
      end,
      mode = 'x',
      desc = 'Select Refactor',
    },
  },
  opts = {},
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
}
