---@type vim.lsp.Config
return {
  cmd = { 'intelephense', '--stdio' },
  init_options = {
    licenceKey = os.getenv 'HOME' .. '/.config/intelephense/licence.txt',
  },
  -- on_attach = function(client)
  --   client.server_capabilities.workspaceSymbolProvider = false
  -- end,
  filetypes = {
    'php',
    'blade',
  },
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
  root_markers = {
    'composer.json',
    '.git',
  },
}
