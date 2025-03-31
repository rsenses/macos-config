---@type vim.lsp.Config
return {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  single_file_support = true,
  settings = {
    tsserver_file_preferences = {
      includeInlayParameterNameHints = 'all',
      includeInlayParameterNameHintsWhenArgumentMatchesName = true,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
      importModuleSpecifierPreference = 'relative',
      importModuleSpecifierEnding = 'minimal',
    },
    typescript = {
      format = {
        enable = true,
      },
      suggest = {
        autoImports = true,
        completeFunctionCalls = true,
      },
      inlayHints = {
        enable = true,
      },
    },
    javascript = {
      format = {
        enable = true,
      },
      suggest = {
        autoImports = true,
        completeFunctionCalls = true,
      },
      inlayHints = {
        enable = true,
      },
    },
  },
}
