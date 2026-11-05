local M = {}

local function reference(absolute, first, last)
  local path = vim.fn.expand(absolute and '%:p' or '%:.')
  if path == '' then
    vim.notify('Buffer has no file name', vim.log.levels.WARN)
    return
  end
  local range = '#L' .. first
  if last ~= first then
    range = range .. '-L' .. last
  end
  return path .. range
end

local function copy(text)
  if text then
    vim.fn.setreg('+', text)
    vim.notify('Copied code reference', vim.log.levels.INFO)
  end
end

function M.copy_reference(absolute, visual)
  local first = visual and vim.fn.line("'<") or vim.fn.line('.')
  local last = visual and vim.fn.line("'>") or first
  copy(reference(absolute, first, last))
end

function M.copy_codeblock()
  local first, last = vim.fn.line("'<"), vim.fn.line("'>")
  local ref = reference(false, first, last)
  if not ref then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local longest = 2
  for _, line in ipairs(lines) do
    for ticks in line:gmatch('`+') do
      longest = math.max(longest, #ticks)
    end
  end
  local fence = string.rep('`', longest + 1)
  local languages = { typescriptreact = 'tsx', javascriptreact = 'jsx' }
  local language = languages[vim.bo.filetype] or vim.bo.filetype
  copy(ref .. '\n\n' .. fence .. language .. '\n' .. table.concat(lines, '\n') .. '\n' .. fence)
end

return M
