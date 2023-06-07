local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<Up>", "<nop>", opts)
vim.keymap.set("n", "<Down>", "<nop>", opts)
vim.keymap.set("n", "<Left>", "<nop>", opts)
vim.keymap.set("n", "<Right>", "<nop>", opts)

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

vim.keymap.set("n", "-", vim.cmd.Ex)
vim.keymap.set("n", "<leader>^", vim.cmd.bnext, { desc =  "Switch next buffer" })

-- When text is wrapped, move by terminal rows, not lines, unless a count is provided
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- vim.keymap.set("n", "J", "mzJ`z") -- No mueve el cursor al unir líneas
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Maintain the cursor position when yanking a visual selection
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set('v', 'y', 'myy`y')
vim.keymap.set('v', 'Y', 'myY`y')

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
vim.keymap.set("n", "<S-Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<S-Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<S-Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<S-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
vim.keymap.set("n", "<S-l>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", opts)

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Easy insertion of a trailing ; or , from insert mode
vim.keymap.set('i', ';;', '<Esc>A;<Esc>')
vim.keymap.set('i', ',,', '<Esc>A,<Esc>')

-- Disable annoying command line thing
vim.keymap.set('n', 'q:', ':q<CR>')

-- Set Esc to nohlsearch
vim.keymap.set('n', '<Esc><Esc>', ':nohlsearch<CR>')

-- Delete buffer with leader+q
vim.keymap.set("n", "<leader>q", "<cmd>bd<CR>", { desc = "[Q]uit buffer"})

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "[P]aste over without yanking"})

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = "[Y]ank to clipboard"})

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = "[D]elete without yanking"})

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "[S]earch current word"})

vim.keymap.set("n", "<leader>vs", "<cmd>setlocal spell spelllang=es<CR>", { desc = '[S]pell' }) -- set spell ON español

-- Undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "[U]ndoTree"})

-- Keymaps for LSP in plugins/lsp.lua
-- Keymaps for test in plugins/vim-test.lua
-- Keymaps for treesitter in plugins/treesitter
