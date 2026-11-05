-- LSPCONFIG

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.fileOperations.willRename = true
capabilities.workspace.fileOperations.didRename = true
vim.lsp.config('*', { capabilities = capabilities })

vim.lsp.enable {
  -- 'laravel_lsp',
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
