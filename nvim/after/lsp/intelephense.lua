---@type vim.lsp.Config
return {
  cmd = { 'intelephense', '--stdio' },
  init_options = {
    licenceKey = os.getenv 'HOME' .. '/.config/intelephense/licence.txt',
  },
  on_attach = function(client)
    client.server_capabilities.workspaceSymbolProvider = false
  end,
  filetypes = {
    'php',
    'blade',
    -- 'php_only',
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
  -- settings = {
  --   intelephense = {
  --     files = {
  --       associations = { '*.php', '*.phtml' },
  --       maxSize = 5000000,
  --     },
  --     environment = {
  --       phpVersion = '8.3.19',
  --     },
  --     telemetry = {
  --       enabled = false,
  --     },
  --     maxMemory = 1024,
  --     completion = {
  --       fullyQualifyGlobalConstantsAndFunctions = true,
  --     },
  --     format = {
  --       enable = false,
  --     },
  --     rename = {
  --       enabled = true,
  --     },
  --   },
  --   php = {
  --     completion = {
  --       callSnippet = 'Replace',
  --     },
  --   },
  -- },
  root_markers = {
    'composer.json',
    '.phpactor.json',
    '.phpactor.yml',
  },
}
