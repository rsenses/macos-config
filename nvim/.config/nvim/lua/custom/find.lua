-- Faster find
local M = {}

local cache = {}
local cache_ttl = 2 * 1e9 -- Refresh at most two seconds after external changes.

local function current_cwd()
  return vim.uv.cwd()
end

local function build_file_list()
  return vim.fn.systemlist {
    'rg',
    '--files',
    '--hidden',
    '--color=never',
    '--glob=!.git',
    '--glob=!node_modules/',
    '--glob=!vendor/',
  }
end

function M.rg_find_files(cmdarg, _)
  local cwd = current_cwd()

  local entry = cache[cwd]
  local now = vim.uv.hrtime()
  if not entry or now - entry.time >= cache_ttl then
    entry = { files = build_file_list(), time = now }
    cache[cwd] = entry
  end

  local files = entry.files

  if cmdarg == '' then
    return files
  end

  return vim.fn.matchfuzzy(files, cmdarg)
end

function M.clear_cache()
  cache = {}
end

function M.setup()
  _G.MyFind = M
  vim.o.findfunc = 'v:lua.MyFind.rg_find_files'

  local group = vim.api.nvim_create_augroup('CustomFindCache', { clear = true })

  vim.api.nvim_create_autocmd({ 'DirChanged', 'FocusGained' }, {
    group = group,
    callback = function()
      M.clear_cache()
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = { 'MiniFilesActionCreate', 'MiniFilesActionDelete', 'MiniFilesActionRename', 'MiniFilesActionMove' },
    callback = M.clear_cache,
  })
end

return M
