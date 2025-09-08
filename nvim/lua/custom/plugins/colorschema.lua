return {
  {
    'zenbones-theme/zenbones.nvim',
    enabled = true,
    lazy = false,
    priority = 1000,
    -- you can set set configuration options here
    config = function()
      vim.o.background = 'light'
      vim.g.zenbones_compat = 1
      vim.cmd.colorscheme 'zenbones'

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'LightGrey', bg = 'LightGrey' })
        end,
      })
    end,
  },
}
