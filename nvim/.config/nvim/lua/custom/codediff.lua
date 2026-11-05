require('codediff').setup {
  explorer = {
    width = 50,
    auto_open_on_cursor = true,
    view_mode = 'tree',
    line_stats = { enabled = true },
  },
  diff = {
    compact = true,
    compact_context_lines = 8,
    compact_sync_folds = true,
  },
}

vim.keymap.set('n', '<leader>dv', '<cmd>CodeDiff<cr>', { desc = 'Review Git changes' })
vim.keymap.set('n', '<leader>dh', '<cmd>CodeDiff history %<cr>', { desc = 'File history' })
vim.keymap.set('n', '<leader>dH', '<cmd>CodeDiff history<cr>', { desc = 'Repository history' })
