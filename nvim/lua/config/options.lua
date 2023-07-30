-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true -- Wrap long lines
vim.opt.conceallevel = 0 -- Not remove anything from json
vim.opt.breakindent = true -- maintain indent when wrapping indented lines
vim.opt.swapfile = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.backup = true -- automatically save a backup file
vim.opt.backupdir:remove(".") -- keep backups out of the current directory
vim.opt.listchars:append("space:·") -- show tabs as »·
vim.opt.spelllang = { "es_es" }
