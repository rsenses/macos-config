return {
    'VonHeikemen/lsp-zero.nvim',
    lazy = false,
    branch = 'v1.x',
    dependencies = {
        -- LSP Support
        { 'neovim/nvim-lspconfig' },
        {
            -- Optional
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
        { 'b0o/schemastore.nvim' }
    },
    config = function()
        local lsp = require("lsp-zero")

        lsp.preset("recommended")

        local cmp = require('cmp')
        local cmp_action = require('lsp-zero').cmp_action()
        local cmp_select = { behavior = cmp.SelectBehavior.Select }
        local cmp_mappings = lsp.defaults.cmp_mappings({
            ['<S-Tab>'] = cmp.mapping.select_prev_item(cmp_select),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Esc>'] = cmp.mapping.close({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<Tab>"] = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item(cmp_select)
                else
                    local copilot_keys = vim.fn["copilot#Accept"]()
                    if copilot_keys ~= "" then
                        vim.api.nvim_feedkeys(copilot_keys, "i", true)
                    else
                        fallback()
                    end
                end
            end,
            ['<C-f>'] = cmp_action.luasnip_jump_forward(),
            ['<C-b>'] = cmp_action.luasnip_jump_backward(),
        })

        lsp.setup_nvim_cmp({
            mapping = cmp_mappings
        })

        lsp.set_preferences({
            suggest_lsp_servers = false,
            sign_icons = { error = "", warn = "", hint = "", info = "" }
        })

        local on_attach = lsp.on_attach(function(client, bufnr)
            lsp.default_keymaps({ buffer = bufnr })

            vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end,
                { buffer = bufnr, remap = false, desc = "[G]oto [D]efinition" })
            vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end,
                { buffer = bufnr, remap = false, desc = "[G]oto [D]eclaration" })
            vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>', { buffer = bufnr })
            vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { buffer = bufnr, remap = false })
            vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end,
                { buffer = bufnr, remap = false, desc = "[F]ormat" })
            vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, { buffer = bufnr, remap = false })
            vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, { buffer = bufnr, remap = false })
            vim.keymap.set("n", "<leader>vc", function() vim.lsp.buf.code_action() end,
                { buffer = bufnr, remap = false, desc = "[C]ode actions" })

            vim.diagnostic.config({
                virtual_text = false
            })
        end)

        lsp.ensure_installed({
            'tsserver',
            'volar',
            'cssls',
            'emmet_ls',
            'html',
            'eslint',
            'jsonls',
            'intelephense',
            'tailwindcss'
        })

        local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

        require('lspconfig').bashls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        require('lspconfig').emmet_ls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        require('lspconfig').html.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        require('lspconfig').intelephense.setup({
            on_attach = function(client, bufnr)
                on_attach(client, bufnr)
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
            end,
            capabilities = capabilities,
        })

        require('lspconfig').jsonls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
                json = {
                    schemas = require('schemastore').json.schemas(),
                },
            },
        })
        require('lspconfig').tailwindcss.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        require('lspconfig').volar.setup({
            on_attach = function(client, bufnr)
                on_attach(client, bufnr)
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
            end,
            on_new_config = function(new_config, new_root_dir)
                new_config.init_options.typescript.serverPath = get_typescript_server_path(new_root_dir)
            end,
            capabilities = capabilities,
            -- Enable "Take Over Mode" where volar will provide all TS LSP services
            -- This drastically improves the responsiveness of diagnostic updates on change
            filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
        })

        lsp.format_mapping('gq', {
            format_opts = {
                async = false,
                timeout_ms = 10000,
            },
            servers = {
                ['null-ls'] = {
                    'javascript',
                    'typescript',
                    'lua',
                    'vue',
                    'php',
                    'html',
                    'css'
                },
            }
        })

        lsp.setup()

        local null_ls = require("null-ls")

        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.formatting.phpcsfixer,
            },
            debug = false,
            -- on_attach = function(client, bufnr)
            --     if client.supports_method("textDocument/formatting") then
            --         vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            --         vim.api.nvim_create_autocmd("BufWritePre", {
            --             group = augroup,
            --             buffer = bufnr,
            --             callback = function()
            --                 vim.lsp.buf.format({ bufnr = bufnr })
            --             end,
            --         })
            --     end
            -- end,
        })

        local ls = require('luasnip')

        ls.config.set_config({
            history = true,
            updateevents = 'TextChanged,TextChangedI',
        })

        ls.add_snippets('php', {
            ls.parser.parse_snippet('class', 'class $1\n{\n    $0\n}'),
            ls.parser.parse_snippet('pubf', 'public function $1($2): $3\n{\n    $0\n}'),
            ls.parser.parse_snippet('prif', 'private function $1($2): $3\n{\n    $0\n}'),
            ls.parser.parse_snippet('prof', 'protected function $1($2): $3\n{\n    $0\n}'),
            ls.parser.parse_snippet('testt', 'public function test_$1()\n{\n    $0\n}'),
            ls.parser.parse_snippet('testa', '/** @test */\npublic function $1()\n{\n    $0\n}'),
        })

        ls.add_snippets('typescript', {
            ls.parser.parse_snippet('import', "import $1 from '$0'"),
        })

        ls.add_snippets('vue', {
            ls.parser.parse_snippet('defineProps', 'defineProps<{\n  $0\n}>()'),
        })
    end
}
