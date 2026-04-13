vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Move lines in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move lines down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move lines up' })

-- Mejoras en los movimientos
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Copiar, pegar y borrar del clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = '[Y]ank to clipboard' })
vim.keymap.set('n', '<leader>Y', [["+Y]], { desc = '[Y]ank to end of line from clipboard' })

-- surround
vim.keymap.set('x', '(', 'c(<ESC>pa)')
vim.keymap.set('x', "'", "c'<ESC>pa'")
vim.keymap.set('x', '"', 'c"<ESC>pa"')
vim.keymap.set('x', '[', 'c[<ESC>pa]')
vim.keymap.set('x', '{', 'c{<ESC>pa}')

-- Easy Escape
vim.keymap.set('i', 'jk', '<esc>')
vim.keymap.set('i', 'kj', '<esc>')
vim.keymap.set('i', 'jj', '<esc>')

-- Splits
vim.keymap.set('n', '<C-w>-', function()
  vim.cmd.split()
end, { desc = 'Split window horizontally' })

vim.keymap.set('n', '<C-w>|', function()
  vim.cmd.vsplit()
end, { desc = 'Split window vertically' })

-- Press 'S' for quick find/replace for the word under the cursor
vim.keymap.set({ 'n' }, 'S', function()
  local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = 'Find and replace word under cursor' })

-- diagnostics
vim.keymap.set('n', 'gl', function()
  vim.diagnostic.open_float()
end, { desc = 'Open diagnostics' })
vim.keymap.set('n', 'grd', function()
  vim.diagnostic.setloclist {
    bufnr = 0,
    open = true,
  }
end, { desc = 'Diagnostics buffer → quickfix' })
vim.keymap.set('n', 'grD', function()
  vim.diagnostic.setqflist { open = true }
end, { desc = 'Diagnostics proyecto → quickfix' })

-- Generic formater
vim.keymap.set('n', '<leader>cF', 'gg=G``', { desc = 'Format the entire file' })

-- undotree
vim.keymap.set('n', '<leader>u', function()
  vim.cmd.packadd 'nvim.undotree'
  require('undotree').open {}
end, { desc = '[U]ndotree' })

-- Buscar texto libremente (escribe el patrón después del comando)
vim.keymap.set('n', '<leader>sg', ':silent grep! ', { desc = 'Grep' })
-- Buscar la palabra bajo el cursor en el directorio actual
vim.keymap.set('n', '<leader>sw', function()
  vim.cmd('silent grep! ' .. vim.fn.expand '<cword>')
end, { desc = 'Grep word' })

-- Buscar archivos
vim.keymap.set('n', '<leader><leader>', ':find ', { desc = 'Find files' })

-- switch between recent buffers
vim.keymap.set('n', '<leader>,', ':b ', { desc = 'List buffers' })
vim.keymap.set('n', '<leader><Tab>', '<C-^>', { desc = 'Last buffer' })

-- Arglist as working set
vim.keymap.set('n', '<leader>aa', function()
  vim.cmd 'argadd %'
  vim.cmd 'argdedupe'
  vim.notify 'Añadido al arglist'
end, { desc = 'Arglist add current file' })

vim.keymap.set('n', '<leader>ad', function()
  vim.cmd 'argdelete %'
  vim.notify 'Eliminado del arglist'
end, { desc = 'Arglist delete current file' })

vim.keymap.set('n', '<leader>al', '<cmd>args<CR>', { desc = 'Arglist list' })

for i = 1, 6 do
  vim.keymap.set('n', '<leader>' .. i, function()
    local count = vim.fn.argc()

    if count < i then
      vim.notify('Arg ' .. i .. ' no existe', vim.log.levels.WARN)
      return
    end

    vim.cmd('argument ' .. i)

    vim.notify(string.format('[%d/%d]', i, count))
  end, { desc = 'Go to arg ' .. i })
end
