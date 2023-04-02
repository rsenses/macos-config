return {
  "rebelot/kanagawa.nvim",
  name = "kanagawa",
  lazy = false,
  priority = 1000,
  config = function()
    -- Kanagawa
    vim.o.background = "dark"

    require('kanagawa').setup({
        transparent = true,         -- do not set background color
      })

    -- setup must be called before loading
    vim.cmd("colorscheme kanagawa")
  end,
}
