return {
  'stevearc/oil.nvim',
  lazy = true,
  opts = {},
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = { -- load the plugin only when using it's keybinding:
    { '-', "<cmd>lua require('oil').open()<cr>", desc = 'Open parent directory' },
  },
}
