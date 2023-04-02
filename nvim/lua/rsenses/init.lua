vim.g.mapleader = " "

require("rsenses.config.options")

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup("rsenses.plugins")

require("rsenses.config.keymaps")
require("rsenses.config.autocommands")
require("rsenses.config.diagnostics")
