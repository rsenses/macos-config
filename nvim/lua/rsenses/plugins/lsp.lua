return {
	"VonHeikemen/lsp-zero.nvim",
	lazy = false,
	branch = "v1.x",
	dependencies = {
		-- LSP Support
		{ "neovim/nvim-lspconfig" },
		{
			-- Optional
			"williamboman/mason.nvim",
			build = function()
				pcall(vim.cmd, "MasonUpdate")
			end,
		},
		{ "williamboman/mason-lspconfig.nvim" },

		-- Autocompletion
		{ "hrsh7th/nvim-cmp" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "saadparwaiz1/cmp_luasnip" },
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-nvim-lua" },

		-- Snippets
		{ "L3MON4D3/LuaSnip" },
		{ "rafamadriz/friendly-snippets" },

		-- Formatter
		{ "jose-elias-alvarez/null-ls.nvim" },
		{ "b0o/schemastore.nvim" },
	},
	config = function()
		local lsp = require("lsp-zero")

		lsp.preset("recommended")

		local cmp = require("cmp")
		local cmp_action = require("lsp-zero").cmp_action()
		local cmp_select = { behavior = cmp.SelectBehavior.Select }
		local luasnip = require("luasnip")
		local cmp_mappings = lsp.defaults.cmp_mappings({
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<Esc>"] = cmp.mapping.close({ select = true }),
			["<C-Space>"] = cmp.mapping.complete(),
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item(cmp_select)
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
					-- local copilot_keys = vim.fn["copilot#Accept"]()
					-- if copilot_keys ~= "" then
					--     vim.api.nvim_feedkeys(copilot_keys, "i", true)
					-- else
					--     fallback()
					-- end
				end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item(cmp_select)
				elseif luasnip.expand_or_jumpable() then
					luasnip.luasnip_jump_backward()
				else
					fallback()
				end
			end, { "i", "s" }),
		})

		lsp.setup_nvim_cmp({
			mapping = cmp_mappings,
		})

		lsp.set_preferences({
			suggest_lsp_servers = false,
			sign_icons = { error = "", warn = "", hint = "", info = "" },
		})

		local on_attach = lsp.on_attach(function(client, bufnr)
			lsp.default_keymaps({ buffer = bufnr })

			vim.keymap.set("n", "gd", function()
				vim.lsp.buf.definition()
			end, { buffer = bufnr, remap = false, desc = "[G]oto [D]efinition" })
			vim.keymap.set("n", "gD", function()
				vim.lsp.buf.declaration()
			end, { buffer = bufnr, remap = false, desc = "[G]oto [D]eclaration" })
			vim.keymap.set("n", "gr", ":Telescope lsp_references<CR>", { buffer = bufnr, desc = "[G]oto [R]eferences" })
			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover()
			end, { buffer = bufnr, remap = false })
			vim.keymap.set("n", "<leader>rn", function()
				vim.lsp.buf.rename()
			end, { buffer = bufnr, remap = false, desc = "[R]ename" })
			vim.keymap.set("n", "<leader>f", function()
				vim.lsp.buf.format()
			end, { buffer = bufnr, remap = false, desc = "[F]ormat" })
			vim.keymap.set("n", "[d", function()
				vim.diagnostic.goto_next()
			end, { buffer = bufnr, remap = false })
			vim.keymap.set("n", "]d", function()
				vim.diagnostic.goto_prev()
			end, { buffer = bufnr, remap = false })
			vim.keymap.set("n", "<leader>vc", function()
				vim.lsp.buf.code_action()
			end, { buffer = bufnr, remap = false, desc = "[C]ode actions" })

			vim.diagnostic.config({
				virtual_text = false,
			})
		end)

		lsp.ensure_installed({
			"tsserver",
			"volar",
			"cssls",
			"emmet_ls",
			"html",
			"bashls",
			"eslint",
			"jsonls",
			"phpactor",
			"tailwindcss",
		})

		local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

		local lspconfig = require("lspconfig")

		lspconfig.emmet_ls.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			filetypes = {
				"css",
				"html",
				"javascript",
				"javascriptreact",
				"less",
				"sass",
				"scss",
				"svelte",
				"typescriptreact",
				"vue",
				"php",
				"blade",
			},
		})

		lspconfig.phpactor.setup({
			on_attach = on_attach,
			init_options = {
				["language_server_phpstan.enabled"] = false,
				["language_server_psalm.enabled"] = false,
			},
			capabilities = capabilities,
		})

		lspconfig.jsonls.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
				},
			},
		})

		lspconfig.volar.setup({
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end,
			capabilities = capabilities,
			-- Enable "Take Over Mode" where volar will provide all TS LSP services
			-- This drastically improves the responsiveness of diagnostic updates on change
			filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
		})

		lsp.format_mapping("gq", {
			format_opts = {
				async = false,
				timeout_ms = 10000,
			},
			servers = {
				["null-ls"] = {
					"javascript",
					"typescript",
					"lua",
					"vue",
					"php",
					"blade",
					"html",
					"css",
				},
			},
		})

		lsp.setup()

		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- Replace these with the tools you have installed
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
			},
		})

		local ls = require("luasnip")

		ls.config.set_config({
			history = true,
			updateevents = "TextChanged,TextChangedI",
		})

		ls.add_snippets("php", {
			ls.parser.parse_snippet("class", "class $1\n{\n    $0\n}"),
			ls.parser.parse_snippet("pubf", "public function $1($2): $3\n{\n    $0\n}"),
			ls.parser.parse_snippet("prif", "private function $1($2): $3\n{\n    $0\n}"),
			ls.parser.parse_snippet("prof", "protected function $1($2): $3\n{\n    $0\n}"),
			ls.parser.parse_snippet("testt", "public function test_$1()\n{\n    $0\n}"),
			ls.parser.parse_snippet("testa", "/** @test */\npublic function $1()\n{\n    $0\n}"),
		})

		ls.add_snippets("typescript", {
			ls.parser.parse_snippet("import", "import $1 from '$0'"),
		})
	end,
}
