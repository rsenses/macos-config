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
vim.keymap.set('x', 'p', [["_dP]], { desc = 'Paste over selection without losing yanked text' })
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = '[Y]ank to clipboard' })

for _, item in ipairs { { 'f', false }, { 'p', true } } do
  vim.keymap.set('n', '<leader>y' .. item[1], function()
    require('custom.references').copy_reference(item[2], false)
  end, { desc = 'Copy file reference' })
  vim.keymap.set('x', '<leader>y' .. item[1], ":<C-u>lua require('custom.references').copy_reference(" .. tostring(item[2]) .. ", true)<CR>",
    { desc = 'Copy selected line range reference' })
end
vim.keymap.set('x', '<leader>cc', ":<C-u>lua require('custom.references').copy_codeblock()<CR>",
  { desc = 'Copy selected lines as Markdown' })

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
vim.keymap.set('n', 'sh', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', 'sj', '<C-w>j', { desc = 'Move to window below' })
vim.keymap.set('n', 'sk', '<C-w>k', { desc = 'Move to window above' })
vim.keymap.set('n', 'sl', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', 'ss', '<cmd>split<CR>', { desc = 'Split window horizontally' })
vim.keymap.set('n', 'sv', '<cmd>vsplit<CR>', { desc = 'Split window vertically' })

vim.keymap.set('n', '<C-w>-', function()
  vim.cmd.split()
end, { desc = 'Split window horizontally' })

vim.keymap.set('n', '<C-w>|', function()
  vim.cmd.vsplit()
end, { desc = 'Split window vertically' })

vim.keymap.set('n', "<C-w>'", function()
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

-- Editor restart
vim.keymap.set('n', '<leader>er', '<cmd>restart<cr>', { desc = 'Restart config :restart' })
vim.keymap.set('n', '<leader>em', 'g<', { desc = 'Open messages pager' })

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
