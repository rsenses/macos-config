vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.title = true

vim.opt.breakindent = true -- maintain indent when wrapping indented lines

vim.opt.swapfile = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.backup = true -- automatically save a backup file
vim.opt.backupdir:remove('.') -- keep backups out of the current directory

vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.termguicolors = true

vim.opt.mouse = 'a' -- enable mouse for all modes
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.confirm = true -- ask for confirmation instead of erroring

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 4
vim.opt.signcolumn = "yes:2"
vim.opt.wildmode = 'longest:full,full' -- complete the longest common match, and allow tabbing the results to fully complete them
vim.opt.cursorline = true -- highlight the current line
vim.opt.list = true -- show whitespace characters
vim.opt.listchars:append('space:·') -- show tabs as »·

vim.opt.updatetime = 4001 -- Set updatime to 1ms longer than the default to prevent polyglot from changing it
vim.opt.redrawtime = 10000 -- Allow more time for loading syntax on large files

-- Tweaks for NetRw
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Only one global Status Line
vim.opt.laststatus = 3
