return {
  {
    'webhooked/kanso.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd 'colorscheme kanso'
    end,
  },
  {
    'zenbones-theme/zenbones.nvim',
    enabled = true,
    lazy = true,
    priority = 1000,
    -- you can set set configuration options here
    config = function()
      --     vim.g.zenbones_darken_comments = 45
      vim.cmd 'colorscheme zenbones'
      vim.g.zenbones_compat = 1
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'LightGrey', bg = 'LightGrey' })
        end,
      })
    end,
  },
}
