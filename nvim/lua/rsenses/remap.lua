vim.g.mapleader = " "

vim.keymap.set("n", "-", vim.cmd.Ex)

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
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "[P]aste over without yanking"})

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = "[Y]ank to clipboard"})

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = "[D]elete without yanking"})

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "[S]earch current word"})

vim.keymap.set("n", "<leader>vs", "<cmd>setlocal spell spelllang=es<CR>", { desc = '[S]pell' }) -- set spell ON español

-- Telescope
vim.keymap.set("n", "<leader>/", require("telescope.builtin").current_buffer_fuzzy_find, { desc = "[/] Search current buffer"})
vim.keymap.set("n", "<leader>pf", require("telescope.builtin").find_files, { desc = "[F]ind files"})
vim.keymap.set("n", "<leader>pg", require("telescope.builtin").live_grep, { desc = "[G]rep find"})
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[B]uffers find"})
vim.keymap.set("n", "<leader>pw", require("telescope.builtin").lsp_workspace_symbols, {desc = "[W]orkspace symbols"})
vim.keymap.set("n", "<leader>ps", require("telescope.builtin").lsp_document_symbols, {desc = "[D]ocument symbols"})
vim.keymap.set("n", "<leader>pc", require("telescope.builtin").git_bcommits, {desc = "[C]ommits current buffer"})
vim.keymap.set("n", "<leader>pC", require("telescope.builtin").git_commits, {desc = "[C]ommits"})
vim.keymap.set("i", "<C-r>", require("telescope.builtin").registers, {desc = "[R]egisters"})
vim.keymap.set("n", "<leader>vd", require("telescope.builtin").diagnostics, {desc = "[D]iagnostics"})
vim.keymap.set("n", "<leader>vh", require("telescope.builtin").help_tags, { desc = "[H]elp tags"})
vim.keymap.set("n", "<leader>vm", require("telescope.builtin").man_pages, { desc = "[M]an pages"})

-- LSP
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, {desc = "[G]oto [D]efinition"})
vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, {desc = "[G]oto [D]eclaration"})
vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, {})
vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end, {desc = "[F]ormat"})
vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, {})
vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, {})
vim.keymap.set("n", "<leader>vc", function() vim.lsp.buf.code_action() end, { desc = "[C]ode actions"})
