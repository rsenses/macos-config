return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v1.x',
  dependencies = {
    -- LSP Support
    { 'neovim/nvim-lspconfig' },
    {                                      -- Optional
      'williamboman/mason.nvim',
      build = function()
        pcall(vim.cmd, 'MasonUpdate')
      end,
    },
    { 'williamboman/mason-lspconfig.nvim' },

    -- Autocompletion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-nvim-lua' },

    -- Snippets
    { 'L3MON4D3/LuaSnip' },
    { 'rafamadriz/friendly-snippets' },

    -- Formatter
    { 'jose-elias-alvarez/null-ls.nvim' },
  },
  config = function()
    local lsp = require("lsp-zero")

    lsp.preset("recommended")

    lsp.ensure_installed({
      'tsserver',
      'vuels',
      'cssls',
      'emmet_ls',
      'html',
      'eslint',
      'jsonls',
      'intelephense',
      'tailwindcss'
    })

    -- Fix Undefined global 'vim'
    lsp.configure('lua-language-server', {
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' }
          }
        }
      }
    })

    local cmp = require('cmp')
    local cmp_select = { behavior = cmp.SelectBehavior.Select }
    local cmp_mappings = lsp.defaults.cmp_mappings({
      ['<S-Tab>'] = cmp.mapping.select_prev_item(cmp_select),
      ['<Tab>'] = cmp.mapping.select_next_item(cmp_select),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),
    })

    -- cmp_mappings['<Tab>'] = nil
    -- cmp_mappings['<S-Tab>'] = nil

    lsp.setup_nvim_cmp({
      mapping = cmp_mappings
    })

    lsp.set_preferences({
      suggest_lsp_servers = false,
      sign_icons = { error = "", warn = "", hint = "", info = "" }
    })

    lsp.on_attach(function(client, bufnr)
      lsp.default_keymaps({ buffer = bufnr })
    end)

    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.phpcsfixer,
      },
      debug = false,
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end
      end,
    })

    lsp.on_attach(function(client, bufnr)
      -- LSP
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { buffer = bufnr, remap = false, desc = "[G]oto [D]efinition"})
      vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, { buffer = bufnr, remap = false, desc = "[G]oto [D]eclaration"})
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { buffer = bufnr, remap = false })
      vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end, { buffer = bufnr, remap = false, desc = "[F]ormat"})
      vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, { buffer = bufnr, remap = false })
      vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, { buffer = bufnr, remap = false })
      vim.keymap.set("n", "<leader>vc", function() vim.lsp.buf.code_action() end, { buffer = bufnr, remap = false, desc = "[C]ode actions"})

    end)

    lsp.setup()

    vim.diagnostic.config({
      virtual_text = false
    })
  end
}
