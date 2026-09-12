-- LSPCONFIG

local capabilities = vim.lsp.protocol.make_client_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

vim.lsp.config('laravel_lsp', {
  cmd = { 'laravel-lsp' },
  filetypes = { 'php', 'blade' },
  root_markers = { 'artisan', 'composer.json', '.git' },
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
  cmd = { 'stylelint-language-server', '--stdio' },
})

vim.lsp.enable {
  'laravel_lsp',
  'phpantom_lsp',
  'html',
  'lua_ls',
  'ts_ls',
  'svelte',
  'marksman',
  'stylelint_lsp',
  'tailwindcss',
}

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: go to definition' })
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
