---@diagnostic disable: missing-fields
return {
  'williamboman/mason.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --  You can press `g?` for help in this menu
    require('mason').setup {
      ui = {
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    }

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys {}
    vim.list_extend(ensure_installed, {
      'html-lsp',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed, automatic_installation = true }

    vim.lsp.enable { 'phpactor', 'intelephense', 'html', 'luals', 'ts_ls', 'emmet', 'markdown', 'stylelint', 'tailwindcss' }

    -- Laravel LS
    -- if vim.fn.filereadable 'artisan' == 1 then
    --   vim.lsp.enable 'laravel-ls'
    -- end
  end,
}
