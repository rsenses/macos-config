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

-- no auto continue comments on new line
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('no_auto_comment', {}),
  callback = function()
    vim.opt_local.formatoptions:remove { 'c', 'r', 'o' }
  end,
})

-- highlight yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- After grep open quickfix
local ggroup = vim.api.nvim_create_augroup('AutoOpenQuickfix', { clear = true })

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = ggroup,
  pattern = { 'lgrep', 'lgrepadd', 'lvimgrep', 'lvimgrepadd' },
  callback = function()
    vim.cmd 'lwindow'
  end,
})
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = ggroup,
  pattern = { 'grep', 'grepadd', 'vimgrep', 'vimgrepadd', 'make' },
  callback = function()
    vim.cmd 'cwindow'
  end,
})

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
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= '' or vim.bo.buftype ~= '' then
    return
  end

  if vim.bo.filetype == 'qf' then
    vim.wo.winbar = ''
    return
  end
  local buffer_count = get_buffer_count()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics_status = vim.diagnostic.status(bufnr)
  local diagnostics = diagnostics_status ~= '' and (' %#WinBar2#' .. diagnostics_status) or ''

  vim.wo.winbar = '%#WinBar1#%m ' .. '%#WinBar2#󰓩' .. buffer_count .. ' ' .. '%#WinBar1# [' .. '%n' .. '] %f' .. diagnostics
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'ModeChanged', 'DiagnosticChanged' }, {
  callback = update_winbar,
})

-- Auto-resize splits when window is resized
local default = vim.api.nvim_create_augroup('user_default', { clear = true })

vim.api.nvim_create_autocmd('VimResized', {
  group = default,
  callback = function()
    vim.cmd 'tabdo wincmd ='
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
    if vim.bo[args.buf].buftype ~= '' then
      return
    end

    guides(vim.bo[args.buf].shiftwidth)
  end,
})

-- Native autocomplete
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.o.signcolumn = 'yes:1'
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, args.buf)
    end
  end,
})
