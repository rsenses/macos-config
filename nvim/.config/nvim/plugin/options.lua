-- [[ Setting options ]]
-- See `:help vim.opt`
-- All files in /plugin folder automatically load

local opt = vim.o
local g = vim.g

-- Disable statusbar
opt.laststatus = 0
opt.cmdheight = 0 -- hide commmand line until needed

-- Basic Settings
opt.number = true -- But show the actual number for the line we're on
opt.relativenumber = true -- Show line numbers
opt.scrolloff = 999 -- Make it so there the cursor is always in the middle
opt.wrap = true

-- Tabbing / Indentation
opt.autoindent = true
opt.cindent = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.breakindent = true
vim.opt.showbreak = string.rep(' ', 3) -- Make it so that long lines wrap smartly
opt.linebreak = true
opt.smartindent = true
opt.grepprg = 'rg --vimgrep' -- Use ripgrep if available
opt.grepformat = '%f:%l:%c:%m' -- filename, line number, column, content

-- Search Settings
opt.incsearch = true -- Makes search act like search in modern browsers
opt.showmatch = true -- show matching brackets when text indicator is over them
opt.hlsearch = true -- I wouldn't use this without my DoNoHL function
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ... unless there is a capital letter in the query

-- Visual Settings
opt.termguicolors = true
g.have_nerd_font = true
opt.colorcolumn = '120'
opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
opt.lazyredraw = false -- redraw while executing macros (butter UX)
opt.redrawtime = 10000 -- Timeout for syntax highlighting redraw
opt.maxmempattern = 20000 -- Max memory for pattern matching
opt.synmaxcol = 300 -- Syntax highlighting column limit
opt.virtualedit = 'block' -- Allow the cursor to move where there is no text in visual block mode
vim.opt.diffopt = { 'internal', 'filler', 'closeoff', 'hiddenoff', 'algorithm:minimal' } -- Better diff options
opt.list = true -- Show some invisible characters (tabs...)
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set listchars
-- vim.opt.listchars:append 'lead:│'
opt.winborder = 'rounded'
opt.background = 'light' -- or 'light'

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
opt.autoread = true -- Auto-reload file if changed outside
opt.autowrite = false -- Don't auto-save on some events
vim.opt.diffopt:append 'vertical' -- Vertical diff splits
vim.opt.diffopt:append 'algorithm:patience' -- Better diff algorithm
vim.opt.diffopt:append 'linematch:60' -- Better diff highlighting (smart line matching)

-- Set undo directory and ensure it exists
local undodir = '~/.local/share/nvim/undodir' -- Undo directory path
vim.opt.undodir = vim.fn.expand(undodir) -- Expand to full path
local undodir_path = vim.fn.expand(undodir)
if vim.fn.isdirectory(undodir_path) == 0 then
  vim.fn.mkdir(undodir_path, 'p') -- Create if not exists
end

-- Behavior Settings
opt.mouse = 'a' -- Enable your mouse
opt.backspace = 'indent,eol,start' -- Make backspace behave naturally
opt.modifiable = true -- Allow editing buffers
opt.encoding = 'UTF-8' -- Use UTF-8 encoding

-- Spell check
g.loaded_spellfile_plugin = 0
g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell/'
vim.opt.spelllang = { 'es_es', 'en_us' }

-- Completions
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'popup', 'fuzzy', 'nosort' }
opt.wildmenu = true -- Enable command-line completion menu
opt.wildmode = 'longest:full,full' -- Completion mode for command-line
opt.wildignorecase = true -- Case-insensitive tab completion in commands

-- Foldings
opt.foldenable = true
opt.foldlevel = 99
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldmethod = 'indent'
opt.foldcolumn = '0'
-- opt.fillchars:append { fold = ' ' }

-- Kulala
vim.filetype.add {
  extension = {
    ['http'] = 'http',
  },
}

-- Faster find
function _G.RgFindFiles(cmdarg, _cmdcomplete)
  local fnames = vim.fn.systemlist 'rg --files --hidden --color=never --glob="!.git" --glob="!node_modules/" --glob="!vendor/"'
  if #cmdarg == 0 then
    return fnames
  else
    return vim.fn.matchfuzzy(fnames, cmdarg)
  end
end
vim.o.findfunc = 'v:lua.RgFindFiles'
