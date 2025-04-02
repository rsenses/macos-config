---@type vim.lsp.Config
return {
  cmd = { 'phpactor', 'language-server' },
  filetypes = { 'php', 'blade' },
  root_markers = {
    'composer.json',
    '.phpactor.json',
    '.phpactor.yml',
  },
  init_options = {
    ['language_server_configuration.auto_config'] = false,
    ['language_server_worse_reflection.inlay_hints.enable'] = true,
    ['language_server_worse_reflection.inlay_hints.types'] = false,
    ['language_server_worse_reflection.inlay_hints.params'] = true,
    ['code_transform.import_globals'] = false,
    ['indexer.exclude_patterns'] = {
      '/vendor/**/Tests/**/*',
      '/vendor/**/tests/**/*',
      '/vendor/composer/**/*',
      '/vendor/laravel/fortify/workbench/**/*',
      '/vendor/filament/forms/.stubs.php',
      '/vendor/filament/notifications/.stubs.php',
      '/vendor/filament/tables/.stubs.php',
      '/vendor/filament/actions/.stubs.php',
      '/storage/framework/cache/**/*',
      '/storage/framework/views/**/*',
      'vendor/kirschbaum-development/eloquent-power-joins/.stubs.php',
      '/vendor/**/_ide_helpers.php',
    },
    ['php_code_sniffer.enabled'] = false,

    ['language_server_phpstan.enabled'] = true,
    ['language_server_phpstan.level'] = '5',
    ['language_server_phpstan.bin'] = '%project_root%/vendor/bin/phpstan',
    ['language_server_phpstan.mem_limit'] = '2048M',
  },
  handlers = {
    ['textDocument/publishDiagnostics'] = function(err, result, ...)
      if vim.endswith(result.uri, 'Test.php') then
        result.diagnostics = vim.tbl_filter(function(diagnostic)
          return (not vim.startswith(diagnostic.message, 'Namespace should probably be "Tests'))
            and (not vim.endswith(diagnostic.message, 'PHPUnit\\Framework\\MockObject\\MockObject given.'))
        end, result.diagnostics)
      end
      if vim.endswith(result.uri, 'blade.php') then
        result.diagnostics = vim.tbl_filter(function(diagnostic)
          return (not vim.startswith(diagnostic.message, 'Undefined variable "$this"'))
        end, result.diagnostics)
      end
      vim.lsp.diagnostic.on_publish_diagnostics(err, result, ...)
    end,

    ['textDocument/inlayHint'] = function(err, result, ...)
      for _, res in ipairs(result or {}) do
        if res.kind == 2 then
          res.label = res.label .. ':'
        end
        res.label = res.label .. ' '
      end
      vim.lsp.handlers['textDocument/inlayHint'](err, result, ...)
    end,
  },
}
