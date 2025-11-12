local api = vim.api
local default = vim.api.nvim_create_augroup('user_default', { clear = true })

-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup('LastCursorGroup', {})
vim.api.nvim_create_autocmd('BufReadPost', {
  group = last_cursor_group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

api.nvim_create_autocmd({ 'FileType' }, {
  desc = 'Force commentstring to include spaces',
  group = default,
  callback = function(event)
    local cs = vim.bo[event.buf].commentstring
    vim.bo[event.buf].commentstring = cs:gsub('(%S)%%s', '%1 %%s'):gsub('%%s(%S)', '%%s %1')
  end,
})

api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Shift numbered registers up (1 becomes 2, etc.)
local function yank_shift()
  for i = 9, 1, -1 do
    vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
  end
end
api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    local event = vim.v.event
    if event.operator == 'y' then
      yank_shift()
    end
  end,
})

-- LSP
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = event.buf, desc = 'LSP: [G]oto [D]eclaration' })

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    -- This may be unwanted, since they displace some of your code
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      vim.keymap.set('n', '<leader>eh', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, { buffer = event.buf, desc = 'LSP: Toggle Inlay [H]ints' })
    end
  end,
})

-- WINBAR
-- Function to get the number of open buffers using the :ls command
local function get_buffer_count()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      count = count + 1
    end
  end
  return count
end

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
  vim.o.winbar = '%#WinBar1#%m ' .. '%#WinBar2#󰓩' .. buffer_count .. ' ' .. '%#WinBar1# %f' .. '%#WinBar2# %=' .. get_full_mode()
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'ModeChanged' }, {
  callback = update_winbar,
})

-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd('VimResized', {
  group = default,
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
})

-- Create directories when saving files
vim.api.nvim_create_autocmd('BufWritePre', {
  group = default,
  callback = function()
    local dir = vim.fn.expand '<afile>:p:h'
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})

-- Enable native undotree
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'nvim-undotree',
--   callback = function()
--     vim.cmd.wincmd 'H'
--     vim.api.nvim_win_set_width(0, 40)
--   end,
-- })

-- === Simple indent guides con exclusión de buffers especiales ===
local NS = vim.api.nvim_create_namespace 'simple_indent_guides'

local function draw_indent_guides(bufnr)
  bufnr = bufnr or 0

  -- Evitar buffers especiales (como mini.starter, ayuda, etc.)
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype
  if bt ~= '' or ft == 'starter' or ft == 'help' or ft == 'TelescopePrompt' or ft == 'lazy' then
    vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  local first = vim.fn.line 'w0'
  local last = vim.fn.line 'w$'
  local sw = vim.bo[bufnr].shiftwidth
  if sw == 0 then
    sw = vim.bo[bufnr].tabstop
  end
  if sw == 0 then
    sw = 4
  end

  for lnum = first, last do
    local indent_cols = vim.fn.indent(lnum)
    if indent_cols > 0 then
      local levels = math.floor(indent_cols / sw)
      for i = 1, levels do
        local col = (i - 1) * sw
        pcall(vim.api.nvim_buf_set_extmark, bufnr, NS, lnum - 1, col, {
          virt_text = { { '│', 'NonText' } },
          virt_text_pos = 'overlay',
          hl_mode = 'combine',
        })
      end
    end
  end
end

local indent_pending = {}
local function schedule_indent_guides(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if indent_pending[bufnr] then
    return
  end
  indent_pending[bufnr] = true
  vim.schedule(function()
    indent_pending[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
      draw_indent_guides(bufnr)
    end
  end)
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'WinScrolled', 'CursorMoved', 'TextChanged', 'TextChangedI', 'InsertLeave' }, {
  callback = function(args)
    schedule_indent_guides(args.buf)
  end,
})

schedule_indent_guides(0)
