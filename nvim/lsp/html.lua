---@type vim.lsp.Config
return {
  cmd = { 'vscode-html-language-server', '--stdio' },
  filetypes = {
    'html',
    'blade',
    'htmldjango',
    'tmpl',
    'gotmpl',
    'template',
    'javascriptreact',
    'typescriptreact',
    'svelte',
  },
  single_file_support = true,
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}
