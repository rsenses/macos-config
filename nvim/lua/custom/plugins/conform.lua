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
    log_level = vim.log.levels.WARN,
    formatters = {
      prettier = {
        prepend_args = { '--ignore-unknown' },
      },
    },
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

      local bufname = vim.api.nvim_buf_get_name(bufnr)

      if bufname:match '/notifications/email.blade.php' then
        return
      else
        return {
          timeout_ms = 2500,
          lsp_format = lsp_format_opt,
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'prettier', stop_after_first = true },
      typescript = { 'prettier', stop_after_first = true },
      typescriptreact = { 'prettier', stop_after_first = true },
      vue = { 'prettier', stop_after_first = true },
      css = { 'prettier', stop_after_first = true },
      scss = { 'prettier', stop_after_first = true },
      less = { 'prettier', stop_after_first = true },
      html = { 'prettier', stop_after_first = true },
      twig = { 'prettier', stop_after_first = true },
      json = { 'prettier', stop_after_first = true },
      jsonc = { 'prettier', stop_after_first = true },
      yaml = { 'prettier', stop_after_first = true },
      markdown = { 'prettier', stop_after_first = true },
      php = { 'pint', 'php_cs_fixer', stop_after_first = true },
      blade = { 'prettier', stop_after_first = true },
      ['*'] = { 'injected' },
    },
    notify_on_error = true,
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
