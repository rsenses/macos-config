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
  -- 'markdown_inline',
  'php',
  -- 'phpdoc',
  'scss',
  'svelte',
  -- 'vim',
  -- 'vimdoc',
  'vue',
  'yaml',
  'sql',
}

ts.install(ensure_installed)

-- `nvim-treesitter` main exposes Neovim's native Treesitter APIs. Highlighting
-- and folding use Neovim's native APIs; indentation is provided by the plugin
-- and is intentionally enabled for buffers with a working parser.

local treesitter_group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = treesitter_group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' then
      return
    end

    local started = pcall(vim.treesitter.start, ev.buf)
    if started then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require('treesitter-context').setup {
  enable = true,
}

require('nvim-ts-autotag').setup {
  opts = {
    enable_close = false,
    enable_rename = true,
    enable_close_on_slash = false,
  },
  aliases = {
    blade = 'html',
    vue = 'html',
  },
  per_filetype = {
    html = { enable_rename = true },
    blade = { enable_rename = true },
    vue = { enable_rename = true },
    javascriptreact = { enable_rename = true },
    typescriptreact = { enable_rename = true },
    jsx = { enable_rename = true },
    tsx = { enable_rename = true },
  },
}

-- END TREESITTER
