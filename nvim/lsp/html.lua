---@type vim.lsp.Config
return {
  filetypes = { 'html', 'htmldjango', 'tmpl', 'gotmpl', 'template' },
  cmd = { 'vscode-html-language-server', '--stdio' },
  single_file_support = true,
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}
