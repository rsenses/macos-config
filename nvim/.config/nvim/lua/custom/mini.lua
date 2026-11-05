-- MINI
local mini_icons = require 'mini.icons'
mini_icons.setup()

vim.api.nvim_create_autocmd('LspAttach', {
  once = true,
  callback = function()
    mini_icons.tweak_lsp_kind()
  end,
})

require('mini.splitjoin').setup()
require('mini.ai').setup()

local bufremove = require 'mini.bufremove'
vim.keymap.set('n', '<leader>bd', bufremove.delete, { desc = '[B]uffer [D]elete' })
vim.keymap.set('n', '<leader>bo', function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and buf ~= current then
      bufremove.delete(buf)
    end
  end
end, { desc = '[B]uffer delete [O]thers' })

require('mini.diff').setup {
  view = {
    signs = { add = '+ ', change = '~ ', delete = '- ' },
  },
  mappings = {
    apply = 'gh',
    reset = 'gH',
    textobject = 'gh',
    goto_first = '[H',
    goto_prev = '[h',
    goto_next = ']h',
    goto_last = ']H',
  },
}

vim.cmd [[
  highlight MiniHipatternsFixme guifg=Black guibg=NvimLightRed gui=bold
  highlight MiniHipatternsHack guifg=Black guibg=NvimLightYellow gui=bold
  highlight MiniHipatternsTodo guifg=Black guibg=NvimLightCyan gui=bold
  highlight MiniHipatternsNote guifg=Black guibg=NvimLightGreen gui=bold
]]

local hipatterns = require 'mini.hipatterns'
hipatterns.setup {
  highlighters = {
    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
}

local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup {
  snippets = {
    gen_loader.from_file '~/.config/nvim/snippets/global.json',
    gen_loader.from_lang {
      extend = { blade = { 'php', 'html' } },
    },
  },
  mappings = {
    expand = '<C-j>',
    jump_next = '<Tab>',
    jump_prev = '<S-Tab>',
    stop = '<C-e>',
  },
}

local miniclue = require 'mini.clue'
miniclue.setup {
  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },
    { mode = 'i', keys = '<C-x>' },
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'x', keys = "'" },
    { mode = 'x', keys = '`' },
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'x', keys = '[' },
    { mode = 'x', keys = ']' },
  },
  clues = {
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    { mode = 'n', keys = '<leader>b', desc = '[B]uffers' },
    { mode = 'n', keys = '<leader>a', desc = '[A]annotations' },
    { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
    { mode = 'n', keys = '<leader>cp', desc = '[C]ode PHP' },
    { mode = 'n', keys = '<leader>d', desc = '[D]atabase' },
    { mode = 'n', keys = '<leader>e', desc = '[E]ditor' },
    { mode = 'n', keys = '<leader>p', desc = '[P]ack' },
    { mode = 'n', keys = '<leader>r', desc = '[R]equests' },
    { mode = 'n', keys = '<leader>s', desc = '[S]earch' },
    { mode = 'n', keys = '<leader>w', desc = '[W]indows' },
    { mode = 'n', keys = '<leader>yy', desc = 'Yank line to clipboard' },
  },
  window = {
    config = {
      anchor = 'SE',
      row = 'auto',
      col = 'auto',
      width = 'auto',
    },
    delay = 500,
    scroll_down = '<C-n>',
    scroll_up = '<C-p>',
  },
}

-- mini files ----
local MiniFiles = require 'mini.files'
MiniFiles.setup {
  mappings = {
    go_in = 'l',
    go_in_plus = '<CR>',
    go_out = 'h',
    go_out_plus = '-',
  },
}

vim.keymap.set('n', '<leader>-', '<cmd>lua MiniFiles.open()<CR>', { desc = 'Toggle mini file explorer' })
vim.keymap.set('n', '-', function()
  MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  MiniFiles.reveal_cwd()
end, { desc = 'Toggle into currently opened file' })

---- mini notify ----
require('mini.notify').setup {
  -- only show messages
  content = {
    format = function(notif)
      return notif.msg
    end,
  },
}

-- END MINI
