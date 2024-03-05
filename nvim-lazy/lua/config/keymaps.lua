local keymap = vim.keymap

keymap.set("n", "<C-h>", ":<C-U>TmuxNavigateLeft<cr>", { desc = "Go to left window" })
keymap.set("n", "<C-j>", ":<C-U>TmuxNavigateDown<cr>", { desc = "Go to lower window" })
keymap.set("n", "<C-k>", ":<C-U>TmuxNavigateUp<cr>", { desc = "Go to upper window" })
keymap.set("n", "<C-l>", ":<C-U>TmuxNavigateRight<cr>", { desc = "Go to right window" })
-- Move lines in visual mode
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up" })
-- Mejoras en los movimientos
keymap.set("n", "J", "mzJ`z")
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")
-- Copiar, pegar y borrar sin usar el registro
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without change register" })
keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without change register" })
