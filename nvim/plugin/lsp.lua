vim.lsp.enable {
  -- 'phpactor',
  'intelephense',
  'html',
  'luals',
  'ts_ls',
  'emmet',
  'markdown',
  'stylelint',
  'tailwindcss',
}

--Diagnostics
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
