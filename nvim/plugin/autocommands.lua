local api = vim.api
local default = vim.api.nvim_create_augroup('user_default', { clear = true })

api.nvim_create_autocmd('BufEnter', {
  desc = 'Stop automatic newline comment',
  pattern = '*',
  callback = function()
    vim.cmd 'set formatoptions-=cro'
    vim.cmd 'setlocal formatoptions-=cro'
  end,
})

api.nvim_create_autocmd({ 'FileType' }, {
  desc = 'Force commentstring to include spaces',
  group = default,
  callback = function(event)
    local cs = vim.bo[event.buf].commentstring
    vim.bo[event.buf].commentstring = cs:gsub('(%S)%%s', '%1 %%s'):gsub('%%s(%S)', '%%s %1')
  end,
})

api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

api.nvim_create_autocmd('FileType', {
  pattern = { 'php', 'blade' },
  callback = function()
    if vim.fn.filereadable 'artisan' == 1 then
      vim.lsp.start {
        name = 'laravel-ls',
        cmd = { 'laravel-ls' },
        root_dir = vim.fn.getcwd(),
      }
    end
  end,
})
