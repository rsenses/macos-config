-- Autoformat
return {
  'stevearc/conform.nvim',
  enabled = true,
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_format = 'fallback', timeout_ms = 2500 }
      end,
      mode = '',
      desc = '[C]ode [F]ormat LSP',
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
  opts = {
    async = true,
    log_level = vim.log.levels.WARN,
    formatters = {
      prettierd = {
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

      if bufname:match '/notifications/email%.blade%.php$' then
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
      javascript = { 'prettierd' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      vue = { 'prettierd' },
      css = { 'prettierd' },
      scss = { 'prettierd' },
      less = { 'prettierd' },
      html = { 'prettierd' },
      twig = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      yaml = { 'prettierd' },
      markdown = { 'prettierd' },
      php = { 'pint', 'php_cs_fixer', stop_after_first = true },
      blade = { 'prettierd' },
    },
    notify_on_error = true,
  },
}
