-- LSPCONFIG
-- vim.lsp.config('html', {
--   filetypes = {
--     'html',
--     'blade',
--   },
-- })

vim.lsp.config('intelephense', {
  init_options = {
    licenceKey = os.getenv 'HOME' .. '/.config/intelephense/licence.txt',
  },
  filetypes = { 'php', 'blade' },
  settings = {
    intelephense = {
      environment = {
        include_paths = {
          './vendor/pestphp',
          './vendor/phpunit/phpunit',
        },
      },
    },
  },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath 'config',
        },
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

vim.lsp.config('stylelint_lsp', {
  cmd = { 'stylelint', '--stdio' },
})

vim.lsp.config['phpantom'] = {
  cmd = { 'phpantom_lsp' },
  filetypes = { 'php', 'blade' },
  root_markers = { 'composer.json', '.git' },
}

vim.lsp.enable {
  'phpantom',
  'html',
  'lua_ls',
  'ts_ls',
  'marksman',
  'stylelint_lsp',
  'tailwindcss',
}
-- END LSPCONFIG

-- Diagnostics
local sev = vim.diagnostic.severity
vim.diagnostic.config {
  virtual_text = true,
  virtual_lines = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  status = {
    format = {
      [sev.ERROR] = '󰅚',
      [sev.WARN] = '󰀪',
      [sev.INFO] = '',
      [sev.HINT] = '󰌶',
    },
  },
  float = {
    border = 'rounded',
    source = true,
  },
  signs = {
    text = {
      [sev.ERROR] = '󰅚 ',
      [sev.WARN] = '󰀪 ',
      [sev.INFO] = ' ',
      [sev.HINT] = '󰌶 ',
    },
  },
}

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: go to definition' })
