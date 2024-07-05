-- You can easily change to a different colorscheme.
return {
  {
    'shaunsingh/nord.nvim',
    name = 'nord',
    priority = 1000,
    lazy = false,
  },
  {
    'rebelot/kanagawa.nvim',
    name = 'kanagawa',
    priority = 1000, -- make sure to load this before all the other start plugins
    lazy = false,
  },
}
