-- LSPCONFIG
vim.lsp.config('html', {
  filetypes = {
    'html',
    'blade',
    'htmldjango',
    'tmpl',
    'gotmpl',
    'template',
  },
})

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

vim.lsp.enable {
  'intelephense',
  'html',
  'lua_ls',
  'ts_ls',
  'marksman',
  'stylelint_lsp',
  'tailwindcss',
}
-- END LSPCONFIG

-- Diagnostics
local signs = { ERROR = '󰅚 ', WARN = '󰀪 ', HINT = '󰌶 ', INFO = ' ' }
local diagnostic_signs = {}
for type, icon in pairs(signs) do
  diagnostic_signs[vim.diagnostic.severity[type]] = icon
end

vim.diagnostic.config {
  virtual_text = true,
  virtual_lines = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = { text = diagnostic_signs },
}

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: go to definition' })
