-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`
-- All files in /plugin folder automatically load

local opt = vim.opt

opt.termguicolors = true
vim.g.have_nerd_font = true

-- Global Status bar
opt.laststatus = 3

-- Cool floating window popup menu for completion on command line
opt.pumblend = 17
opt.wildmode = 'longest:full'
opt.wildoptions = 'pum'

opt.showcmd = true
opt.cmdheight = 1 -- Height of the command bar
opt.incsearch = true -- Makes search act like search in modern browsers
opt.showmatch = true -- show matching brackets when text indicator is over them
opt.relativenumber = true -- Show line numbers
opt.number = true -- But show the actual number for the line we're on
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ... unless there is a capital letter in the query
opt.hidden = true -- I like having buffers stay around
opt.equalalways = false -- I don't like my windows changing all the time
opt.splitright = true -- Prefer windows splitting to the right
opt.splitbelow = true -- Prefer windows splitting to the bottom
opt.updatetime = 1000 -- Make updates happen faster
opt.timeoutlen = 300
opt.hlsearch = true -- I wouldn't use this without my DoNoHL function
opt.scrolloff = 10 -- Make it so there are always ten lines below my cursor
opt.cursorline = true -- Highlight the current line

-- Tabs
opt.autoindent = true
opt.cindent = true
opt.wrap = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true

opt.breakindent = true
opt.showbreak = string.rep(' ', 3) -- Make it so that long lines wrap smartly
opt.linebreak = true

opt.foldmethod = 'expr'
opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- opt.nofoldenable = true
opt.foldlevel = 99 -- All folds open by default

opt.belloff = 'all' -- Just turn the dang bell off

opt.clipboard = 'unnamedplus'

-- Save undo history
opt.undofile = true

-- Preview substitutions live, as you type!
opt.inccommand = 'split'

-- Enable mouse
opt.mouse = 'a'

-- Helpful related items:
--   1. :center, :left, :right
--   2. gw{motion} - Put cursor back after formatting motion.
--
-- opt.formatoptions = opt.formatoptions
--   - 'a' -- Auto formatting is BAD.
--   - 't' -- Don't auto format my code. I got linters for that.
--   + 'c' -- In general, I like it when comments respect textwidth
--   + 'q' -- Allow formatting comments w/ gq
--   - 'o' -- O and o, don't continue comments
--   + 'r' -- But do continue when pressing enter.
--   + 'n' -- Indent past the formatlistpat, not underneath it.
--   + 'j' -- Auto-remove comments if possible.
--   - '2' -- I'm not in gradeschool anymore
--
-- -- set joinspaces
-- opt.joinspaces = false -- Two spaces and grade school, we're done
--
-- -- set fillchars=eob:~
-- opt.fillchars = { eob = '~' }
--
-- opt.diffopt = { 'internal', 'filler', 'closeoff', 'hiddenoff', 'algorithm:minimal' }

opt.undofile = true

-- Keep signcolumn on by default
opt.signcolumn = 'yes'

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Show which line your cursor is on
opt.cursorline = true

-- Spell check
vim.g.loaded_spellfile_plugin = 0
vim.g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell/'
opt.spelllang = { 'es_es', 'en_us' }

-- THEMES
opt.background = 'dark' -- or 'light'
vim.cmd.colorscheme 'nord'
