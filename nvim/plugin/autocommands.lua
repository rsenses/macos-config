-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local api = vim.api

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- stop automatic newline comment
api.nvim_create_autocmd('BufEnter', {
  pattern = '*',
  callback = function()
    vim.cmd 'set formatoptions-=cro'
    vim.cmd 'setlocal formatoptions-=cro'
  end,
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
api.nvim_create_autocmd('FileType', {
  pattern = { 'json', 'jsonc', 'markdown' },
  callback = function()
    vim.opt.conceallevel = 0
  end,
})

-- Filetypes --
vim.filetype.add {
  pattern = {
    ['.*.blade.php'] = 'blade',
    ['.*.html.twig'] = 'twig',
  },
}
