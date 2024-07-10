-- You can easily change to a different colorscheme.
return {
  -- {
  --   'shaunsingh/nord.nvim',
  --   name = 'nord',
  --   priority = 1000,
  --   lazy = false,
  -- },
  {
    'zenbones-theme/zenbones.nvim',
    name = 'zenbones',
    priority = 1000,
    lazy = false,
    dependencies = {
      'rktjmp/lush.nvim',
    },
  },
  {
    'scottmckendry/cyberdream.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('cyberdream').setup {
        -- Enable italics comments
        italic_comments = true,
        theme = {
          variant = 'auto', -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`
        },
      }
    end,
  },
  -- {
  --   'rebelot/kanagawa.nvim',
  --   name = 'kanagawa',
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   lazy = false,
  -- },
  -- {
  --   'ishan9299/nvim-solarized-lua',
  --   name = 'solarized',
  --   priority = 1000,
  --   lazy = false,
  -- },
  {
    'folke/tokyonight.nvim',
    name = 'tokyonight',
    priority = 1000,
    lazy = false,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    lazy = false,
  },
}
