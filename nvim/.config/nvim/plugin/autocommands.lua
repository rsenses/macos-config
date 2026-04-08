local default = vim.api.nvim_create_augroup('user_default', { clear = true })

-- open help in vertical split
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'help',
  command = 'wincmd L',
})

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

-- vim.api.nvim_create_autocmd({ 'FileType' }, {
--   desc = 'Force commentstring to include spaces',
--   group = default,
--   callback = function(event)
--     local cs = vim.bo[event.buf].commentstring
--     vim.bo[event.buf].commentstring = cs:gsub('(%S)%%s', '%1 %%s'):gsub('%%s(%S)', '%%s %1')
--   end,
-- })

-- no auto continue comments on new line
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('no_auto_comment', {}),
  callback = function()
    vim.opt_local.formatoptions:remove { 'c', 'r', 'o' }
  end,
})

-- highlight yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  pattern = '*',
  desc = 'highlight selection on yank',
  callback = function()
    vim.highlight.on_yank { timeout = 200, visual = true }
  end,
})

-- show cursorline only in active window enable
local cursorline_group = vim.api.nvim_create_augroup('active_cursorline', { clear = true })

vim.api.nvim_create_autocmd('WinEnter', {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = true
  end,
})

vim.api.nvim_create_autocmd('WinLeave', {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = false
  end,
})
-- vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
--   group = vim.api.nvim_create_augroup('active_cursorline', { clear = true }),
--   callback = function()
--     vim.opt_local.cursorline = true
--   end,
-- })

-- show cursorline only in active window disable
-- vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
--   group = 'active_cursorline',
--   callback = function()
--     vim.opt_local.cursorline = false
--   end,
-- })

-- Shift numbered registers up (1 becomes 2, etc.)
-- local function yank_shift()
--   for i = 9, 1, -1 do
--     vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
--   end
-- end
-- vim.api.nvim_create_autocmd('TextYankPost', {
--   callback = function()
--     local event = vim.v.event
--     if event.operator == 'y' then
--       yank_shift()
--     end
--   end,
-- })

-- LSP
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
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

-- Function to update the winbar
local function update_winbar()
  local buffer_count = get_buffer_count()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics_status = vim.diagnostic.status(bufnr)
  local diagnostics = diagnostics_status ~= '' and (' %#WinBar2#' .. diagnostics_status) or ''

  vim.wo.winbar = '%#WinBar1#%m ' .. '%#WinBar2#󰓩' .. buffer_count .. ' ' .. '%#WinBar1# %f' .. diagnostics
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'ModeChanged', 'DiagnosticChanged' }, {
  callback = update_winbar,
})

-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd('VimResized', {
  group = default,
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
})

-- Enable native undotree
local undotree_group = vim.api.nvim_create_augroup('user_undotree', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = undotree_group,
  pattern = 'nvim-undotree',
  desc = 'Move undotree window to the left and set fixed width',
  callback = function()
    vim.cmd.wincmd 'H'
    vim.api.nvim_win_set_width(0, 40)
  end,
})

-- === Simple indent guides con exclusión de buffers especiales ===
local augroup = vim.api.nvim_create_augroup('indentlines', {})

local function guides(sw)
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  local char = '┆' .. (' '):rep(sw - 1)
  vim.opt_local.listchars:append { leadmultispace = char }
end

vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'shiftwidth',
  group = augroup,
  callback = function()
    guides(vim.v.option_new)
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = augroup,
  callback = function(args)
    guides(vim.bo[args.buf].shiftwidth)
  end,
})

-- Remove whitespace end of line
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    local ft = vim.bo.filetype
    local bt = vim.bo.buftype

    -- Excluir buffers no normales
    if bt ~= '' then
      return
    end

    -- Excluir filetypes concretos
    local excluded_filetypes = {
      markdown = true,
      diff = true,
      gitcommit = true,
    }

    if excluded_filetypes[ft] then
      return
    end

    local save = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(save)
  end,
})

-- Native autocomplete
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_completion', { clear = true }),
  callback = function(args)
    local client_id = args.data.client_id
    if not client_id then
      return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if client and client:supports_method 'textDocument/completion' then
      -- Enable native LSP completion for this client + buffer
      vim.lsp.completion.enable(true, client_id, args.buf, {
        autotrigger = true, -- auto-show menu as you type (recommended)
        -- You can also set { autotrigger = false } and trigger manually with <C-x><C-o>
      })
    end
  end,
})
