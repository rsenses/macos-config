return {
  "rebelot/kanagawa.nvim",
  name = "kanagawa",
  lazy = false,
  priority = 1000,
  config = function()
    -- Kanagawa
    vim.o.background = "dark"

    -- setup must be called before loading
    vim.cmd("colorscheme kanagawa")
  end,
}
