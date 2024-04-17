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

-- Filetypes --
vim.filetype.add {
  pattern = {
    ['.*%.blade%.php'] = 'blade',
    ['.*.html.twig'] = 'twig',
  },
}

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'json', 'jsonc', 'markdown', 'md' },
  callback = function()
    vim.opt.conceallevel = 0
    vim.wo.conceallevel = 0
  end,
})

-- local group = api.nvim_create_augroup('CursorLineControl', { clear = true })
-- local set_cursorline = function(event, value, pattern)
--   api.nvim_create_autocmd(event, {
--     group = group,
--     pattern = pattern,
--     callback = function()
--       vim.opt_local.cursorline = value
--     end,
--   })
-- end
-- set_cursorline('WinLeave', false)
-- set_cursorline('WinEnter', true)
-- set_cursorline('FileType', false, 'TelescopePrompt')

-- Set spell to tru on markdown
api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text', 'md' },
  callback = function()
    vim.opt_local.spell = true
  end,
})
