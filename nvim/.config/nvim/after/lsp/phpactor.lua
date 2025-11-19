---@type vim.lsp.Config
return {
  cmd = { 'phpactor', 'language-server' },
  filetypes = { 'php', 'blade' },
  root_markers = { '.git', 'composer.json', '.phpactor.json', '.phpactor.yml' },
  workspace_required = true,
  settings = {
    phpactor = {
      language_server_phpstan = { enabled = true },
      language_server_psalm = { enabled = false },
      phpunit = { enabled = true },
      inlayHints = {
        enable = true,
        parameterHints = true,
        typeHints = true,
      },
    },
  },
}
