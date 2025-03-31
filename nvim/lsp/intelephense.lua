---@type vim.lsp.Config
return {
  cmd = { 'intelephense', '--stdio' },
  init_options = {
    licenceKey = os.getenv 'HOME' .. '/.config/intelephense/licence.txt',
  },
  filetypes = { 'php', 'blade' },
  settings = {
    intelephense = {
      files = {
        associations = { '*.php', '*.phtml' },
        maxSize = 5000000,
      },
      environment = {
        phpVersion = '8.3.19',
      },
      telemetry = {
        enabled = false,
      },
      maxMemory = 1024,
      completion = {
        fullyQualifyGlobalConstantsAndFunctions = true,
      },
      format = {
        enable = true,
      },
      rename = {
        enabled = true,
      },
    },
  },
  root_markers = {
    'composer.json',
    '.phpactor.json',
    '.phpactor.yml',
  },
}
