-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`
-- All files in /plugin folder automatically load

local opt = vim.opt
local g = vim.g

opt.termguicolors = true
g.have_nerd_font = true

-- Global Status bar
-- opt.laststatus = 3
-- Disable statusbar
opt.laststatus = 0

opt.incsearch = true -- Makes search act like search in modern browsers
opt.showmatch = true -- show matching brackets when text indicator is over them
opt.inccommand = 'split' -- Make substitution work in realtime
opt.relativenumber = true -- Show line numbers
opt.number = true -- But show the actual number for the line we're on
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ... unless there is a capital letter in the query
opt.splitright = true -- Prefer windows splitting to the right
opt.splitbelow = true -- Prefer windows splitting to the bottom
opt.hlsearch = true -- I wouldn't use this without my DoNoHL function
opt.scrolloff = 999 -- Make it so there the cursor is always in the middle
opt.cursorline = true -- Highlight the current line
opt.virtualedit = 'block' -- Allow the cursor to move where there is no text in visual block mode
opt.mouse = 'a' -- Enable your mouse
opt.diffopt = { 'internal', 'filler', 'closeoff', 'hiddenoff', 'algorithm:minimal' } -- Better diff options
opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
opt.list = true -- Show some invisible characters (tabs...)
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Set listchars
opt.undofile = true -- Save undo history to file

-- Tabs
opt.autoindent = true
opt.cindent = true
opt.wrap = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.breakindent = true
opt.showbreak = string.rep(' ', 3) -- Make it so that long lines wrap smartly
opt.linebreak = true

-- Spell check
g.loaded_spellfile_plugin = 0
g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell/'
opt.spelllang = { 'es_es', 'en_us' }

-- THEMES
opt.background = 'light' -- or 'light'

-- Foldings
-- opt.foldmethod = 'expr'
-- opt.foldexpr = 'nvim_treesitter#foldexpr()'
opt.foldmethod = 'indent'
opt.foldlevelstart = 99

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
-- vim.cmd(string.format [[highlight WinBar1 guifg=NvimDarkGreen guibg=NvimLightGray3]])
-- vim.cmd(string.format [[highlight WinBar2 guifg=NvimDarkRed guibg=NvimLightGray3]])
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
-- Function to update the winbar
local function update_winbar()
  local buffer_count = get_buffer_count()
  opt.winbar = '%#WinBar1#%m ' .. '%#WinBar2#󰓩' .. buffer_count .. ' ' .. '%#WinBar1# %f'
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  callback = update_winbar,
})

-- Completions
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.shortmess:append 'c'
