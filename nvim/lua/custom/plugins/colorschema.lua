return {
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    enabled = true,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'dayfox'
    end,
  },
}
