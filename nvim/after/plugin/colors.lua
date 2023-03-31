-- TokyoNight
-- vim.o.background = "dark"
--
-- require("tokyonight").setup({
--   -- your configuration comes here
--   -- or leave it empty to use the default settings
--   style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
--   transparent = true, -- Enable this to disable setting the background color
--   terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
-- })
--
-- vim.cmd('colorscheme tokyonight')

-- Moonfly
-- vim.cmd [[colorscheme moonfly]]
-- vim.g.moonflyTransparent = true
-- vim.g.moonflyNormalFloat = true

-- Kanagawa
vim.o.background = "dark"

require('kanagawa').setup({
    transparent = true,         -- do not set background color
})

-- setup must be called before loading
vim.cmd("colorscheme kanagawa")
