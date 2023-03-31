vim.g.mapleader = " "

vim.keymap.set("n", "-", vim.cmd.Lex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- Visual --
-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = '[P]aste over without yanking'})

-- next greatest remap ever : asbjornHaland
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = '[Y]ank to clipboard'})

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = '[D]elete without yanking'})

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = '[S]earch current word'})

-- Telescope
vim.keymap.set('n', '<leader>pf', require('telescope.builtin').find_files, { desc = '[F]ind files'})
vim.keymap.set('n', '<leader>vh', require('telescope.builtin').help_tags, { desc = '[H]elp tags'})
vim.keymap.set('n', '<leader>pg', require('telescope.builtin').live_grep, { desc = '[G]rep find'})
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[B]uffers find'})

-- LSP
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, {})
vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, {})
vim.keymap.set("n", "<leader>pw", function() vim.lsp.buf.workspace_symbol() end, {desc = '[W]orkspace symbols'})
vim.keymap.set("n", "<leader>ps", function() vim.lsp.buf.document_symbol() end, {desc = '[D]ocument symbols'})
vim.keymap.set("n", "<leader>vd", '<cmd>lua vim.diagnostic.open_float({ border = "rounded" })<CR>', {desc = '[D]iagnostics'})
vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end, {desc = '[F]ormat'})
vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, {})
vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, {})
