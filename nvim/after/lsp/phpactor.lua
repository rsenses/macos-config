---@type vim.lsp.Config
return {
  cmd = { 'phpactor', 'language-server' },
  filetypes = { 'php' },
  root_markers = {
    'composer.json',
    '.phpactor.json',
    '.phpactor.yml',
  },
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
    client.server_capabilities.documentSymbolProvider = false
    client.server_capabilities.referencesProvider = false
    client.server_capabilities.completionProvider = false
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.definitionProvider = false
    client.server_capabilities.implementationProvider = true
    client.server_capabilities.typeDefinitionProvider = false
    client.server_capabilities.diagnosticProvider = false
  end,
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
  init_options = {
    ['language_server_worse_reflection.inlay_hints.enable'] = true,
    ['language_server_worse_reflection.inlay_hints.types'] = false,
    ['language_server_worse_reflection.inlay_hints.params'] = true,
    ['phpunit.enabled'] = true,
    ['language_server_phpstan.enabled'] = true,
    ['language_server_phpstan.level'] = '5',
    ['language_server_phpstan.bin'] = '%project_root%/vendor/bin/phpstan',
    ['language_server_phpstan.mem_limit'] = '2048M',
    ['language_server_reference_reference_finder.reference_timeout'] = 600,
  },
}
