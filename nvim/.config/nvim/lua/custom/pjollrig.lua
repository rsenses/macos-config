require('pjollrig').setup {
  sinks = {
    clipboard = { resolve = false },
  },
}

-- Comment drafts are prose; avoid native completion invoking synchronous Markdown LSP callbacks.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('PjollrigCommentOptions', { clear = true }),
  pattern = 'markdown',
  callback = function(event)
    if vim.api.nvim_buf_get_name(event.buf):match('^pjollrig%-comment://') then
      vim.bo[event.buf].autocomplete = false
    end
  end,
})

vim.keymap.set({ 'n', 'x' }, '<leader>aa', ':Pjollrig add<cr>', { desc = 'Add review comment' })
vim.keymap.set('n', '<leader>ac', '<cmd>Pjollrig send clipboard<cr>', { desc = 'Copy review as Markdown' })
vim.keymap.set('n', '<leader>ad', '<cmd>Pjollrig delete<cr>', { desc = 'Delete review comment' })
vim.keymap.set('n', '<leader>al', '<cmd>Pjollrig list<cr>', { desc = 'List review comments' })
