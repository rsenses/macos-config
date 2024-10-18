-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local api = vim.api
local default = vim.api.nvim_create_augroup('user_default', { clear = true })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
api.nvim_create_autocmd({ 'TextYankPost' }, {
  desc = 'Highlight when yanking text',
  group = default,
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- stop automatic newline comment
-- api.nvim_create_autocmd('BufEnter', {
--   pattern = '*',
--   callback = function()
--     vim.cmd 'set formatoptions-=cro'
--     vim.cmd 'setlocal formatoptions-=cro'
--   end,
-- })

api.nvim_create_autocmd({ 'FileType' }, {
  desc = 'Force commentstring to include spaces',
  group = default,
  callback = function(event)
    local cs = vim.bo[event.buf].commentstring
    vim.bo[event.buf].commentstring = cs:gsub('(%S)%%s', '%1 %%s'):gsub('%%s(%S)', '%%s %1')
  end,
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'json', 'jsonc', 'markdown', 'md' },
  callback = function()
    vim.opt.conceallevel = 0
    vim.wo.conceallevel = 0
  end,
})

-- Set spell to tru on markdown
api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text', 'md' },
  callback = function()
    vim.opt_local.spell = true
  end,
})
