-- Faster find
local M = {}

local cache = {}

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

  if not cache[cwd] then
    cache[cwd] = build_file_list()
  end

  local files = cache[cwd]

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

  vim.api.nvim_create_autocmd('DirChanged', {
    group = group,
    callback = function()
      M.clear_cache()
    end,
  })
end

return M
