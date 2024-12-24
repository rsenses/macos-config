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
