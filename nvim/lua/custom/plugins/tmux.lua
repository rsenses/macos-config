return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  config = function()
    -- Tmux navigation
    vim.keymap.set('n', '<C-h>', ':<C-U>TmuxNavigateLeft<cr>', { desc = 'Go to left window' })
    vim.keymap.set('n', '<C-j>', ':<C-U>TmuxNavigateDown<cr>', { desc = 'Go to lower window' })
    vim.keymap.set('n', '<C-k>', ':<C-U>TmuxNavigateUp<cr>', { desc = 'Go to upper window' })
    vim.keymap.set('n', '<C-l>', ':<C-U>TmuxNavigateRight<cr>', { desc = 'Go to right window' })
  end,
}
