--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Clipboard
if vim.fn.has 'mac' == 1 then
  vim.opt.clipboard = 'unnamedplus'
elseif vim.fn.has 'linux' == 1 then
  vim.g.clipboard = 'osc52'
  vim.opt.clipboard = 'unnamedplus'
end

-- Experimental UI2: floating cmdline and messages
require('vim._core.ui2').enable {}
-- recuerda g< para abrir los mensajes

-- [[ Configure and install plugins ]]
--  Plugin revisions are tracked in `nvim-pack-lock.json`.
require 'custom.pack'

-- Faster find files
require('custom.find').setup()
