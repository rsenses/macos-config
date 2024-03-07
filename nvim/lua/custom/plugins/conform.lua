-- Autoformat
return {
  'stevearc/conform.nvim',
  dependencies = { 'mason.nvim' },
  lazy = true,
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      mode = { 'n', 'v' },
      desc = '[C]ode [F]ormat LSP',
    },
  },
  opts = {
    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 10000,
    },
    formatters_by_ft = {
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use a sub-list to tell conform to run *until* a formatter
      -- is found.

      lua = { 'stylua' },
      javascript = { 'prettier' },
      typescript = { 'prettier' },
      vue = { 'prettier' },
      css = { 'prettier' },
      scss = { 'prettier' },
      less = { 'prettier' },
      html = { { 'prettier' } },
      twig = { 'prettier' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      php = { 'pint' },
      blade = { 'blade-formatter' },
    },
  },
}
