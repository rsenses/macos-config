-- Autoformat
return {
  'stevearc/conform.nvim',
  dependencies = { 'williamboman/mason.nvim' },
  event = { 'BufReadPre', 'BufNewFile' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_fallback = true, timeout_ms = 5000 }
      end,
      mode = { 'n', 'v' },
      desc = '[C]ode [F]ormat LSP',
    },
  },
  opts = {
    format_on_save = {
      lsp_fallback = true,
      async = false,
      timeout_ms = 5000,
    },
    formatters_by_ft = {
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use a sub-list to tell conform to run *until* a formatter
      -- is found.

      lua = { 'stylua' },
      javascript = { 'prettierd' },
      typescript = { 'prettierd' },
      vue = { 'prettierd' },
      css = { 'prettierd' },
      scss = { 'prettierd' },
      less = { 'prettierd' },
      html = { { 'prettierd' } },
      twig = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      yaml = { 'prettierd' },
      markdown = { 'prettierd' },
      php = { 'pint' },
      blade = { 'blade-formatter' },
    },
    notify_on_error = true,
  },
}
