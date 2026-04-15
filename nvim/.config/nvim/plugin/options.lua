-- [[ Setting options ]]
-- See `:help vim.opt`
-- All files in /plugin folder automatically load

local opt = vim.o
local g = vim.g

-- Disable statusbar
opt.laststatus = 0
opt.cmdheight = 0
-- Experimental UI2: floating cmdline and messages
require('vim._core.ui2').enable {}
-- recuerda g< para abrir los mensajes

-- Basic Settings
opt.number = true -- But show the actual number for the line we're on
opt.relativenumber = true -- Show line numbers
opt.scrolloff = 999 -- Make it so there the cursor is always in the middle

-- Tabbing / Indentation
opt.wrap = false
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.breakindent = true
vim.opt.showbreak = string.rep(' ', 3) -- Make it so that long lines wrap smartly
opt.linebreak = true

-- Search Settings
opt.showmatch = true -- show matching brackets when text indicator is over them
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ... unless there is a capital letter in the query
opt.grepprg = 'rg --vimgrep --no-heading --no-messages --smart-case'

-- Visual Settings
opt.cursorline = true
opt.termguicolors = true
g.have_nerd_font = true
vim.opt.colorcolumn = '120'
opt.signcolumn = 'yes:1' -- Always show the signcolumn, otherwise it would shift the text each time
opt.redrawtime = 10000 -- Timeout for syntax highlighting redraw
opt.maxmempattern = 20000 -- Max memory for pattern matching
opt.synmaxcol = 300 -- Syntax highlighting column limit
opt.virtualedit = 'block' -- Allow the cursor to move where there is no text in visual block mode
vim.opt.diffopt:append { 'algorithm:patience', 'vertical', 'linematch:60' }
vim.opt.shortmess:append 'c'
opt.list = true -- Show some invisible characters (tabs...)
vim.opt.listchars = { tab = '- ', trail = '·', nbsp = '␣' } -- Set listchars
-- vim.opt.listchars:append 'lead:│'
opt.winborder = 'rounded'

-- Split Behavior
opt.inccommand = 'split' -- Make substitution work in realtime
opt.splitright = true -- Prefer windows splitting to the right
opt.splitbelow = true -- Prefer windows splitting to the bottom

-- File Handling
opt.undofile = true -- Save undo history to file
opt.confirm = true
opt.updatetime = 300 -- Time in ms to trigger CursorHold
opt.timeoutlen = 500 -- Time in ms to wait for mapped sequence
opt.ttimeoutlen = 0 -- No wait for key code sequences

-- Set undo directory and ensure it exists
local undodir = '~/.local/share/nvim/undodir' -- Undo directory path
vim.opt.undodir = vim.fn.expand(undodir) -- Expand to full path
local undodir_path = vim.fn.expand(undodir)
if vim.fn.isdirectory(undodir_path) == 0 then
  vim.fn.mkdir(undodir_path, 'p') -- Create if not exists
end

-- Behavior Settings
vim.opt.smoothscroll = true
opt.mouse = 'a' -- Enable your mouse
-- disable mouse popup yet keep mouse enabled
vim.cmd [[
  aunmenu PopUp
  autocmd! nvim.popupmenu
]]

-- Spell check
g.loaded_spellfile_plugin = 0
g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell/'
vim.opt.spelllang = { 'es_es', 'en_us' }

-- Completions
-- vim.o.complete = 'o,.,w,b,u'
vim.o.complete = 'o,.,w,b'
vim.opt.completeopt = { 'menu', 'menuone', 'fuzzy', 'popup', 'noinsert', 'noselect' }
opt.autocomplete = true
opt.wildmode = 'longest:full,full' -- Completion mode for command-line
-- opt.wildmode = 'full' -- Completion mode for command-line
opt.wildignorecase = true -- Case-insensitive tab completion in commands
vim.opt.shortmess:prepend 'c' -- avoid having to press enter on snippet completion
vim.opt.path:append { '**' }
vim.opt.wildignore = {
  '*/node_modules/*',
  '*/.git/*',
  '*/dist/*',
  '*/build/*',
  '*/vendor/*',
  '*.lock',
}

-- Foldings
opt.foldlevel = 99
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldmethod = 'indent'
opt.foldcolumn = '0'
-- opt.fillchars:append { fold = ' ' }
