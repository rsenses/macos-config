---@type vim.lsp.Config
return {
  cmd = { 'marksman', 'server' },
  filetypes = {
    'markdown',
    'markdown.mdx',
  },
  root_markers = { '.git', '.marksman.toml' },
}
