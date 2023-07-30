-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmd = vim.api.nvim_create_autocmd
-- stop automatic newline comment
autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.cmd("set formatoptions-=cro")
  end,
})
autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.cmd("setlocal formatoptions-=cro")
  end,
})
