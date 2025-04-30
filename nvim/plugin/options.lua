-- [[ Setting options ]]
-- See `:help vim.opt`
-- All files in /plugin folder automatically load

local opt = vim.opt
local g = vim.g

opt.termguicolors = true
g.have_nerd_font = true

-- Disable statusbar
opt.laststatus = 0
opt.cmdheight = 0 -- hide commmand line until needed

opt.incsearch = true -- Makes search act like search in modern browsers
opt.showmatch = true -- show matching brackets when text indicator is over them
opt.hlsearch = true -- I wouldn't use this without my DoNoHL function
opt.inccommand = 'split' -- Make substitution work in realtime
opt.number = true -- But show the actual number for the line we're on
opt.relativenumber = true -- Show line numbers
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ... unless there is a capital letter in the query
opt.splitright = true -- Prefer windows splitting to the right
opt.splitbelow = true -- Prefer windows splitting to the bottom
opt.scrolloff = 999 -- Make it so there the cursor is always in the middle
opt.cursorline = true -- Highlight the current line
opt.virtualedit = 'block' -- Allow the cursor to move where there is no text in visual block mode
opt.mouse = 'a' -- Enable your mouse
opt.diffopt = { 'internal', 'filler', 'closeoff', 'hiddenoff', 'algorithm:minimal' } -- Better diff options
opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
opt.list = true -- Show some invisible characters (tabs...)
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set listchars
opt.undofile = true -- Save undo history to file
opt.confirm = true

opt.wrap = true
opt.colorcolumn = '120'

-- Tabs
opt.autoindent = true
opt.cindent = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.breakindent = true
opt.showbreak = string.rep(' ', 3) -- Make it so that long lines wrap smartly
opt.linebreak = true
opt.smartindent = true

-- Spell check
g.loaded_spellfile_plugin = 0
g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell/'
opt.spelllang = { 'es_es', 'en_us' }

-- Completions
vim.o.completeopt = 'noselect,menu,menuone,noinsert,popup'
-- opt.completeopt = { 'menu', 'menuone', 'noselect' }
-- opt.shortmess:append 'c'

-- THEMES
opt.background = 'light' -- or 'light'

-- Foldings
-- Nice and simple folding:
vim.o.foldenable = true
vim.o.foldlevel = 99
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldmethod = 'indent'
opt.foldcolumn = '0'
-- opt.fillchars:append { fold = ' ' }

-- These sessionoptions come from the lazyvim distro, I just added localoptions
-- https://www.lazyvim.org/configuration/general
opt.sessionoptions = {
  'buffers',
  'curdir',
  'tabpages',
  'winsize',
  'help',
  'globals',
  'skiprtp',
  'folds',
  'localoptions',
}

-- WINBAR
-- Function to get the number of open buffers using the :ls command
local function get_buffer_count()
  local buffers = vim.fn.execute 'ls'
  local count = 0
  -- Match only lines that represent buffers, typically starting with a number followed by a space
  for line in string.gmatch(buffers, '[^\r\n]+') do
    if string.match(line, '^%s*%d+') then
      count = count + 1
    end
  end
  return count
end

-- local function get_full_mode()
--   local mode = vim.api.nvim_eval 'mode()'
--   local mode_names = {
--     n = 'NORMAL',
--     no = 'N·OPER',
--     nov = 'N·VIRT',
--     niI = 'N·INTR',
--     v = 'VISUAL',
--     V = 'V·LINE',
--     [''] = 'V·BLCK',
--     s = 'SELECT',
--     S = 'S·LINE',
--     [''] = 'S·BLCK',
--     i = 'INSERT',
--     R = 'REPLACE',
--     Rv = 'V·REPL',
--     c = 'COMMAND',
--     cv = 'VIM EX',
--     ce = 'EX EDIT',
--     r = 'PROMPT',
--     rm = 'MORE',
--     ['r?'] = 'CONFIRM',
--     t = 'TERMINAL',
--     ['!'] = 'SHELL',
--   }
--   return mode_names[mode] or mode
-- end

local function get_full_mode()
  local modes = {
    ['n'] = 'NORMAL',
    ['no'] = 'NORMAL',
    ['v'] = 'VISUAL',
    ['V'] = 'VISUAL LINE',
    [''] = 'VISUAL BLOCK',
    ['s'] = 'SELECT',
    ['S'] = 'SELECT LINE',
    [''] = 'SELECT BLOCK',
    ['i'] = 'INSERT',
    ['ic'] = 'INSERT',
    ['R'] = 'REPLACE',
    ['Rv'] = 'VISUAL REPLACE',
    ['c'] = 'COMMAND',
    ['cv'] = 'VIM EX',
    ['ce'] = 'EX',
    ['r'] = 'PROMPT',
    ['rm'] = 'MOAR',
    ['r?'] = 'CONFIRM',
    ['!'] = 'SHELL',
    ['t'] = 'TERMINAL',
  }
  local current_mode = vim.api.nvim_get_mode().mode
  return string.format('%s ', modes[current_mode]):upper()
end

-- Function to update the winbar
local function update_winbar()
  local buffer_count = get_buffer_count()
  opt.winbar = '%#WinBar1#%m ' .. '%#WinBar2#󰓩' .. buffer_count .. ' ' .. '%#WinBar1# %f' .. '%#WinBar2# %=' .. get_full_mode()
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'ModeChanged' }, {
  callback = update_winbar,
})
