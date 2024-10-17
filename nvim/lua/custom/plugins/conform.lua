-- Autoformat
return {
  'stevearc/conform.nvim',
  dependencies = { 'williamboman/mason.nvim' },
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_format = 'fallback', timeout_ms = 5000 }
      end,
      mode = '',
      desc = '[C]ode [F]ormat LSP',
    },
  },
  opts = {
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = 'never'
      else
        lsp_format_opt = 'fallback'
      end
      return {
        timeout_ms = 2500,
        lsp_fallback = true,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters_by_ft = {
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      lua = { 'stylua' },
      javascript = { { 'prettierd', 'prettier' } },
      typescript = { { 'prettierd', 'prettier' } },
      vue = { { 'prettierd', 'prettier' } },
      css = { { 'prettierd', 'prettier' } },
      scss = { { 'prettierd', 'prettier' } },
      less = { { 'prettierd', 'prettier' } },
      html = { { 'prettierd', 'prettier' } },
      twig = { { 'prettierd', 'prettier' } },
      json = { { 'prettierd', 'prettier' } },
      jsonc = { { 'prettierd', 'prettier' } },
      yaml = { { 'prettierd', 'prettier' } },
      markdown = { { 'prettierd', 'prettier' } },
      php = { { 'pint', 'php_cs_fixer' } },
      blade = { 'blade-formatter' },
    },
    notify_on_error = true,
  },
}
