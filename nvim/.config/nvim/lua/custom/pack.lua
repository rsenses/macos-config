vim.pack.add({
  'https://github.com/christoomey/vim-tmux-navigator',
  'https://github.com/kristijanhusak/vim-dadbod-completion',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/mistweaverco/kulala.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-mini/mini.nvim',
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
    version = 'main',
  },
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/oskarnurm/koda.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/stevearc/quicker.nvim',
  'https://github.com/supermaven-inc/supermaven-nvim',
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/windwp/nvim-ts-autotag',
}, {
  confirm = false,
  load = true,
})

-- COLORSCHEMA
vim.o.background = 'light'

require('koda').setup {
  transparent = true,
  styles = {
    functions = { bold = true },
    keywords = {},
    comments = { italic = true },
    strings = { italic = true },
    constants = { bold = true },
  },
  colors = {
    bg = '#FAF4ED',
    fg = '#2d3035',
    dim = '#ffffff',
    line = '#F8EFE5',
    comment = '#8E877F',
    border = '#2d3035',
    keyword = '#5A2E2A',
    emphasis = '#B4637A',
    func = '#33363c',
    const = '#356B6A',
    string = '#5F6B2D',
    highlight = '#6B4E2E',
    info = '#066E89',
    success = '#2F6B3F',
    warning = '#ff9f19',
    danger = '#e14e30',
  },
}

vim.cmd 'colorscheme koda'

vim.api.nvim_set_hl(0, 'Visual', { bg = '#EEDFCF' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = '#F4E7D9' })
vim.api.nvim_set_hl(0, 'PmenuSel', { bg = '#D6D8C4', bold = true })
-- END COLORSCHEMA

-- CONFORM
require('conform').setup {
  async = true,
  log_level = vim.log.levels.WARN,
  formatters = {
    prettierd = {
      prepend_args = { '--ignore-unknown' },
    },
  },
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback'
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if bufname:match '/notifications/email%.blade%.php$' then
      return
    end

    return {
      timeout_ms = 2500,
      lsp_format = lsp_format_opt,
    }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd' },
    typescript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    vue = { 'prettierd' },
    css = { 'prettierd' },
    scss = { 'prettierd' },
    less = { 'prettierd' },
    html = { 'prettierd' },
    twig = { 'prettierd' },
    json = { 'prettierd' },
    jsonc = { 'prettierd' },
    yaml = { 'prettierd' },
    markdown = { 'prettierd' },
    php = { 'pint', 'php_cs_fixer', stop_after_first = true },
    blade = { 'prettierd' },
  },
  notify_on_error = true,
}

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.keymap.set('', '<leader>cf', function()
  require('conform').format { async = true, lsp_format = 'fallback', timeout_ms = 2500 }
end, { desc = '[C]ode [F]ormat LSP' })
-- END CONFORM

-- DADBOD
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_save_location = vim.fn.stdpath 'data' .. '/dadbod_queries'
vim.g.db_ui_winwidth = 35
vim.o.previewheight = 30
vim.g.db_ui_show_help = 0
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_force_echo_notifications = 1

local dbfile = vim.fn.getcwd() .. '/.db.lua'
if vim.fn.filereadable(dbfile) == 1 then
  local ok, project_dbs = pcall(dofile, dbfile)
  if ok and type(project_dbs) == 'table' then
    vim.g.dbs = vim.tbl_extend('force', vim.g.dbs or {}, project_dbs)
  end
end

vim.g.db_ui_table_helpers = {
  mysql = {
    List = 'SELECT * FROM `{dbname}`.`{table}` ORDER BY id DESC LIMIT 200',
    Count = 'SELECT COUNT(*) AS total FROM `{dbname}`.`{table}`',
    ['Last 50'] = 'SELECT * FROM `{dbname}`.`{table}` ORDER BY id DESC LIMIT 50',
    ['Filter template'] = [[
SELECT *
FROM `{dbname}`.`{table}`
WHERE 1 = 1
LIMIT 200
]],
  },
  sqlite = {
    List = 'SELECT * FROM `{table}` ORDER BY id DESC LIMIT 200',
    Count = 'SELECT COUNT(*) AS total FROM `{table}`',
    ['Last 50'] = 'SELECT * FROM `{table}` ORDER BY id DESC LIMIT 50',
    ['Filter template'] = [[
SELECT *
FROM `{table}`
WHERE 1 = 1
LIMIT 200
]],
  },
}

vim.keymap.set('n', '<leader>du', '<cmd>DBUIToggle<cr>', { desc = 'Dadbod UI' })
vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Dadbod find buffer' })
vim.keymap.set('n', '<leader>dr', '<cmd>DBUIRenameBuffer<cr>', { desc = 'Dadbod rename buffer' })
vim.keymap.set('n', '<leader>dl', '<cmd>DBUILastQueryInfo<cr>', { desc = 'Dadbod last query info' })
-- END DADBOD

-- KULALA
require('kulala').setup {
  global_keymaps = true,
  global_keymaps_prefix = '<leader>r',
  kulala_keymaps_prefix = '',
}
-- END KULALA

-- MINI
local mini_icons = require 'mini.icons'
mini_icons.setup()

vim.api.nvim_create_autocmd('LspAttach', {
  once = true,
  callback = function()
    mini_icons.tweak_lsp_kind()
  end,
})

require('mini.extra').setup()
require('mini.splitjoin').setup()
require('mini.ai').setup()

local pick = require 'mini.pick'
pick.setup()

vim.keymap.set('n', '<leader><leader>', function()
  pick.builtin.cli({
    command = {
      'fd',
      '--type',
      'f',
      '--hidden',
      '--no-ignore',
      '--exclude',
      '.git',
      '--exclude',
      'node_modules',
      '--exclude',
      'vendor',
    },
  }, { source = { cwd = vim.fn.getcwd() } })
end, { desc = 'Find files' })

vim.keymap.set('n', '<leader>sg', '<Cmd>Pick grep_live tool="rg"<CR>', { desc = 'Grep' })
vim.keymap.set({ 'n', 'x' }, '<leader>sw', '<Cmd>Pick grep pattern="<cword>"<CR>', { desc = 'Visual selection or word' })
vim.keymap.set('n', '<leader>sD', '<Cmd>Pick diagnostic scope="all"<CR>', { desc = 'Diagnostics' })
vim.keymap.set('n', '<leader>sd', '<Cmd>Pick diagnostic scope="current"<CR>', { desc = 'Buffer Diagnostics' })
vim.keymap.set('n', '<leader>sr', '<Cmd>Pick registers<CR>', { desc = 'Registers' })
vim.keymap.set('n', 'grr', '<Cmd>Pick lsp scope="references"<CR>', { nowait = true, desc = 'References' })
vim.keymap.set('n', '<leader>ss', '<Cmd>Pick lsp scope="document_symbol"<CR>', { desc = 'LSP Symbols' })

local bufremove = require 'mini.bufremove'
vim.keymap.set('n', '<leader>bd', bufremove.delete, { desc = '[B]uffer [D]elete' })
vim.keymap.set('n', '<leader>bp', function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      bufremove.delete(buf)
    end
  end
end, { desc = '[B]uffer [P]urge (all)' })

vim.keymap.set('n', '<leader>bo', function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and buf ~= current then
      bufremove.delete(buf)
    end
  end
end, { desc = '[B]uffer delete [O]thers' })

local starter = require 'mini.starter'
starter.setup {
  header = table.concat({
    '   _       _        _           ',
    ' _| |_____| |_  ___| |__  _   _ ',
    "|_   _|_  / __|/ __| '_ \\| | | |",
    '  |_|  /__\\__ \\ (__| | | | |_| |',
    '           |___/\\___|_| |_|\\__, |',
    '                            |___/ ',
  }, '\n'),
  items = {
    starter.sections.recent_files(10, true),
    { name = 'Edit config', action = 'e $MYVIMRC', section = 'Actions' },
    { name = 'Find files', action = 'Pick files', section = 'Actions' },
  },
  footer = function()
    local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1] or ''
    return root ~= '' and ('Git: ' .. vim.fn.fnamemodify(root, ':t')) or ''
  end,
}

require('mini.notify').setup()

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

require('mini.completion').setup {
  fallback_action = '<C-f>',
  mappings = {
    force_twostep = '<C-Space>',
    force_fallback = '<A-Space>',
    scroll_down = '<C-n>',
    scroll_up = '<C-p>',
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
    { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
    { mode = 'n', keys = '<leader>cp', desc = '[C]ode PHP' },
    { mode = 'n', keys = '<leader>e', desc = '[E]ditor' },
    { mode = 'n', keys = '<leader>es', desc = '[S]pelling' },
    { mode = 'n', keys = '<leader>esl', desc = '[L]anguage' },
    { mode = 'n', keys = '<leader>g', desc = '[G]it' },
    { mode = 'n', keys = '<leader>r', desc = '[R]equests' },
    { mode = 'n', keys = '<leader>s', desc = '[S]earch' },
    { mode = 'n', keys = '<leader>t', desc = '[T]est' },
    { mode = 'n', keys = '<leader>w', desc = '[W]indows' },
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
-- END MINI

-- OIL
require('oil').setup {
  default_file_explorer = true,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    autosave_changes = true,
  },
  view_options = {
    show_hidden = true,
    natural_order = true,
    is_always_hidden = function(name)
      local ignored_files = { '.git', 'node_modules', '.idea', '.DS_Store' }
      return vim.tbl_contains(ignored_files, name)
    end,
  },
  win_options = {
    wrap = true,
    winblend = 0,
  },
  keymaps = {
    ['<C-c>'] = false,
    q = 'actions.close',
  },
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
-- END OIL

-- QUICKER
require('quicker').setup {
  keys = {
    {
      '>',
      function()
        require('quicker').expand { before = 2, after = 2, add_to_existing = true }
      end,
      desc = 'Expand quickfix context',
    },
    {
      '<',
      function()
        require('quicker').collapse()
      end,
      desc = 'Collapse quickfix context',
    },
  },
}
-- END QUICKER

-- MARKDOWN
require('render-markdown').setup {
  file_types = { 'markdown' },
  completions = { lsp = { enabled = true } },
}
-- END MARKDOWN

-- SUPERMAVEN
require('supermaven-nvim').setup {
  keymaps = {
    clear_suggestion = '<C-e>',
    accept_word = '<C-j>',
  },
  ignore_filetypes = { cpp = true },
  color = {
    suggestion_color = '#888888',
    cterm = 244,
  },
  log_level = 'info',
  disable_inline_completion = false,
  disable_keymaps = false,
}
-- END SUPERMAVEN

-- TMUX
vim.keymap.set('n', '<c-h>', '<cmd>TmuxNavigateLeft<cr>')
vim.keymap.set('n', '<c-j>', '<cmd>TmuxNavigateDown<cr>')
vim.keymap.set('n', '<c-k>', '<cmd>TmuxNavigateUp<cr>')
vim.keymap.set('n', '<c-l>', '<cmd>TmuxNavigateRight<cr>')
-- END TMUX

-- TREESITTER
local ts = require 'nvim-treesitter'
local ensure_installed = {
  'blade',
  'css',
  'diff',
  'gitignore',
  'html',
  'javascript',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'php',
  'phpdoc',
  'scss',
  'vim',
  'vimdoc',
  'vue',
  'yaml',
}

ts.install(ensure_installed)

ts.setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
-- END TREESITTER

local treesitter_group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = treesitter_group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' then
      return
    end

    pcall(vim.treesitter.start, ev.buf)
  end,
})

require('treesitter-context').setup {
  enable = true,
}

require('mini.comment').setup {
  options = {
    custom_commentstring = function()
      local ok, parser = pcall(vim.treesitter.get_parser, 0)
      if not ok or not parser then
        return nil
      end

      local ft = vim.bo.filetype
      local curline = vim.fn.line '.' - 1
      local ok_lang, langobj = pcall(parser.language_for_range, parser, { curline, 0, curline, 0 })
      if not ok_lang or not langobj then
        return nil
      end

      local lang = langobj:lang()
      if ft == 'blade' then
        if lang == 'php' or lang == 'php_only' or lang == 'javascript' then
          return '// %s'
        elseif lang == 'css' then
          return '/* %s */'
        end
        return '{{-- %s --}}'
      elseif ft == 'php' then
        return '// %s'
      end

      return nil
    end,
  },
}

require('nvim-ts-autotag').setup {
  opts = {
    enable_close = false,
    enable_rename = true,
    enable_close_on_slash = false,
  },
  aliases = {
    blade = 'html',
  },
  per_filetype = {
    html = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
    },
  },
}
