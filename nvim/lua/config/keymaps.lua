-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
-- vim.keymap.del("n", "<C-h>")
-- vim.keymap.del("n", "<C-j>")
-- vim.keymap.del("n", "<C-k>")
-- vim.keymap.del("n", "<C-l>")
vim.keymap.set("n", "<C-h>", ":<C-U>TmuxNavigateLeft<cr>", { desc = "Go to left window", remap = true })
vim.keymap.set("n", "<C-j>", ":<C-U>TmuxNavigateDown<cr>", { desc = "Go to lower window", remap = true })
vim.keymap.set("n", "<C-k>", ":<C-U>TmuxNavigateUp<cr>", { desc = "Go to upper window", remap = true })
vim.keymap.set("n", "<C-l>", ":<C-U>TmuxNavigateRight<cr>", { desc = "Go to right window", remap = true })
-- Not LSP formatter
vim.keymap.set("n", "<Leader>cf", "gg=G''", { desc = "Go to right window", remap = true })
-- Move lines in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down", remap = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up", remap = true })
-- Mejoras en los movimientos
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
-- Copiar, pegar y borrar sin usar el registro
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
