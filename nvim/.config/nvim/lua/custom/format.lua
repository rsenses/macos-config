-- CONFORM
require('conform').setup {
  async = true,
  log_level = vim.log.levels.WARN,
  formatters = {
    prettierd = {
      prepend_args = { '--ignore-unknown' },
    },
  },
  format_on_save = function(bufnr)
    if vim.b[bufnr].disable_autoformat then
      return
    end
    local disable_filetypes = { c = true, cpp = true }
    local filetype = vim.bo[bufnr].filetype
    local lsp_format_opt = disable_filetypes[filetype] and 'never' or 'fallback'
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if filetype == 'http' or bufname:match '/notifications/email%.blade%.php$' then
      return
    end

    return {
      timeout_ms = 2500,
      lsp_format = lsp_format_opt,
    }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd' },
    typescript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    vue = { 'prettierd' },
    svelte = { 'prettierd' },
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
}

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.keymap.set('', '<leader>cf', function()
  require('conform').format { async = true, lsp_format = 'fallback', timeout_ms = 2500 }
end, { desc = '[C]ode [F]ormat LSP' })

vim.api.nvim_create_user_command('ToggleFormatter', function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  vim.notify('Format on save ' .. (vim.b.disable_autoformat and 'disabled' or 'enabled') .. ' for this buffer')
end, { desc = 'Toggle format on save for the current buffer' })
-- END CONFORM
