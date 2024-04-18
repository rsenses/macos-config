vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })

-- Move lines in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move lines down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move lines up' })

-- Mejoras en los movimientos
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Copiar, pegar y borrar sin usar el registro, x lo hace por defecto, para no llenar de basurilla el registro
vim.keymap.set('x', '<leader>p', [["_dP]], { desc = 'Paste without change register' })
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]], { desc = 'Delete without change register' })
vim.keymap.set({ 'n', 'v' }, 'x', [["_x]], { desc = 'Delete without change register' })
vim.keymap.set({ 'n', 'v' }, 'X', [["_X]], { desc = 'Delete without change register' })

-- Splits
vim.keymap.set('n', '<C-w>-', function()
  vim.cmd.split()
end, { desc = 'Split window horizontally' })

vim.keymap.set('n', '<C-w>|', function()
  vim.cmd.vsplit()
end, { desc = 'Split window vertically' })

-- Resize window using <ctrl> arrow keys
vim.keymap.set('n', '<C-w>k', '<cmd>resize +10<cr>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-w>j', '<cmd>resize -10cr>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-w>h', '<cmd>vertical resize -10<cr>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-w>l', '<cmd>vertical resize +10<cr>', { desc = 'Increase window width' })

-- Trabajo con buffers
vim.keymap.set('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set({ 'n' }, '<leader>bd', ':bd<cr>', { desc = 'Delete Buffer' })
vim.keymap.set({ 'n' }, '<leader>bp', ':bufdo bd<cr>', { desc = 'Delete all Buffers' })

-- Formatting
vim.keymap.set({ 'n', 'v' }, '<leader>cF', 'gg=G', { desc = '[C]ode [F]ormat' })

-- Press 'S' for quick find/replace for the word under the cursor
vim.keymap.set({ 'n' }, 'S', function()
  local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = 'Find and replace word under cursor' })

-- lazy
vim.keymap.set('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- mason
vim.keymap.set('n', '<leader>m', '<cmd>Mason<cr>', { desc = 'Mason' })

-- Netrw
-- vim.keymap.set({ 'n' }, '-', '<CMD>Ex<CR>', { desc = 'Open parent directory' })
