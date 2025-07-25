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
vim.keymap.set({ 'n', 'v' }, '<leader>p', [["+p]], { desc = '[P]aste from clipboard' })
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]], { desc = '[D]elete to clipboard' })
-- copy everything between { } including the brackets
vim.keymap.set('n', 'YY', 'va{Vy', { desc = '[C]opy between { }' })

-- Autopairs
-- vim.keymap.set('i', "'", "''<left>")
-- vim.keymap.set('i', '"', '""<left>')
-- vim.keymap.set('i', '`', '``<left>')
-- vim.keymap.set('i', '(', '()<left>')
-- vim.keymap.set('i', '[', '[]<left>')
-- vim.keymap.set('i', '{', '{}<left>')

-- Easy Escape
vim.keymap.set('i', 'jk', '<esc>')
vim.keymap.set('i', 'kj', '<esc>')

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

-- lazy
vim.keymap.set('n', '<leader>wl', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- mason
-- vim.keymap.set('n', '<leader>wm', '<cmd>Mason<cr>', { desc = 'Mason' })

-- diagnostics
vim.keymap.set('n', 'gl', function()
  vim.diagnostic.open_float()
end, { desc = 'Open diagnostics' })

-- Generic formater
vim.keymap.set('n', '<leader>cF', 'gg=G``', { desc = 'Format the entire file' })

-- Open terminal in tmux
vim.keymap.set({ 'n' }, '<leader>-', '<cmd>silent !tmux split-window<CR>', { desc = '[E]ditor [T]erminal' })
vim.keymap.set({ 'n' }, '<leader>|', '<cmd>silent !tmux split-window -h -l 60<CR>', { desc = '[E]ditor [T]erminal' })

-- [[ SPELLING]]

-- Keymap to switch spelling language to English lamw25wmal
-- To save the language settings configured on each buffer, you need to add
-- "localoptions" to vim.opt.sessionoptions in the `lua/config/options.lua` file
vim.keymap.set('n', '<leader>esle', function()
  vim.opt.spelllang = 'en'
  vim.cmd "echo 'Spell language set to English'"
end, { desc = '[S]pelling language English' })

-- Keymap to switch spelling language to Spanish lamw25wmal
vim.keymap.set('n', '<leader>esls', function()
  vim.opt.spelllang = 'es'
  vim.cmd "echo 'Spell language set to Spanish'"
end, { desc = '[S]pelling language Spanish' })

-- Keymap to switch spelling language to both spanish and english lamw25wmal
vim.keymap.set('n', '<leader>eslb', function()
  vim.opt.spelllang = 'en,es'
  vim.cmd "echo 'Spell language set to Spanish and English'"
end, { desc = '[S]pelling language Spanish and English' })

-- Show spelling suggestions / spell suggestions
vim.keymap.set('n', '<leader>ess', function()
  -- Simulate pressing "z=" with "m" option using feedkeys
  -- vim.api.nvim_replace_termcodes ensures "z=" is correctly interpreted
  -- 'm' is the {mode}, which in this case is 'Remap keys'. This is default.
  -- If {mode} is absent, keys are remapped.
  --
  -- I tried this keymap as usually with
  vim.cmd 'normal! 1z='
  -- But didn't work, only with nvim_feedkeys
  -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z=", true, false, true), "m", true)
end, { desc = '[S]pelling suggestions' })

-- markdown good, accept spell suggestion
-- Add word under the cursor as a good word
vim.keymap.set('n', '<leader>esg', function()
  vim.cmd 'normal! zg'
end, { desc = '[S]pelling add word to spellfile' })

-- Undo zw, remove the word from the entry in 'spellfile'.
vim.keymap.set('n', '<leader>esu', function()
  vim.cmd 'normal! zug'
end, { desc = '[S]pelling undo, remove word from list' })

-- Repeat the replacement done by |z=| for all matches with the replaced word
-- in the current window.
vim.keymap.set('n', '<leader>esr', function()
  -- vim.cmd(":spellr")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':spellr\n', true, false, true), 'm', true)
end, { desc = '[S]pelling repeat' })

-- Tests
vim.keymap.set('n', '<leader>ta', function()
  local file_path = vim.fn.expand '%:p'
  local escaped_file_path = vim.fn.shellescape(file_path)
  local command = string.format('tmux new-window "./vendor/bin/pest; exec zsh"', escaped_file_path)
  vim.fn.system(command)
end, { desc = '[T]est [A]ll' })
vim.keymap.set('n', '<leader>ta', function()
  local file_path = vim.fn.expand '%:p'
  local escaped_file_path = vim.fn.shellescape(file_path)
  local command = string.format('tmux new-window "./vendor/bin/pest --bail; exec zsh"', escaped_file_path)
  vim.fn.system(command)
end, { desc = '[T]est [B]ail' })
vim.keymap.set('n', '<leader>tc', function()
  local file_path = vim.fn.expand '%:p'
  local escaped_file_path = vim.fn.shellescape(file_path)
  local command = string.format('tmux new-window "./vendor/bin/pest %s; exec zsh"', escaped_file_path)
  vim.fn.system(command)
end, { desc = '[T]est [C]urrent file' })

vim.keymap.set({ 'n', 'x' }, '<leader>ca', function()
  require('tiny-code-action').code_action()
end, { noremap = true, silent = true })
