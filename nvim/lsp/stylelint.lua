---@type vim.lsp.Config
return {
  cmd = { 'stylelint', '--stdio' },
  filetypes = {
    'css',
    'less',
    'scss',
    'sass',
    'sugarss',
    'vue',
    'wxss',
  },
  root_markers = {
    '.git',
    '.stylelintrc',
    '.stylelintrc.cjs',
    '.stylelintrc.js',
    '.stylelintrc.json',
    '.stylelintrc.yaml',
    '.stylelintrc.yml',
    'stylelint.config.cjs',
    'stylelint.config.js',
  },
}
