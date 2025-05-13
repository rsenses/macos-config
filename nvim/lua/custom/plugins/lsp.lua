---@diagnostic disable: missing-fields
return {
  'williamboman/mason.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = event.buf, desc = 'LSP: [G]oto [D]eclaration' })

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        -- This may be unwanted, since they displace some of your code
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          vim.keymap.set('n', '<leader>eh', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, { buffer = event.buf, desc = 'LSP: Toggle Inlay [H]ints' })
        end
      end,
    })

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
      'blade-formatter',
      'emmet-ls',
      'eslint_d',
      'html-lsp',
      'phpactor',
      'intelephense',
      'pint',
      'prettier',
      'stylua',
      'tailwindcss-language-server',
      'typescript-language-server',
      'marksman',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed, automatic_installation = true }

    vim.lsp.enable { 'phpactor', 'intelephense', 'html', 'luals', 'ts_ls', 'emmet', 'markdown', 'stylelint', 'tailwindcss' }

    -- Laravel LS
    -- if vim.fn.filereadable 'artisan' == 1 then
    --   vim.lsp.enable 'laravel-ls'
    -- end
  end,
}
