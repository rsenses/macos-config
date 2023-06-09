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

		-- Formatter
		{ "jose-elias-alvarez/null-ls.nvim" },
	},
	config = function()
		local lsp = require("lsp-zero")

		lsp.preset("recommended")

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

		lsp.setup()

		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- Replace these with the tools you have installed
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.blade_formatter,
				null_ls.builtins.formatting.phpcsfixer,
			},
		})

		local cmp = require("cmp")
		local luasnip = require("luasnip")

		require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snippets" })

		local types = require("cmp.types")

		local cmp_mappings = lsp.defaults.cmp_mappings({
			["<A-CR>"] = cmp.mapping.confirm({
				behavior = cmp.ConfirmBehavior.Insert,
				select = true,
			}),
			["<CR>"] = cmp.mapping.confirm({
				behavior = cmp.ConfirmBehavior.Insert,
				select = false,
			}),
			["<Tab>"] = cmp.mapping(function(fallback)
				if luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
			["<C-n>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item({ behavior = types.cmp.SelectBehavior.Select })
					-- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
					-- they way you will only jump inside the snippet region
				else
					fallback()
				end
			end, { "i", "s" }),
			["<C-p>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item({ behavior = types.cmp.SelectBehavior.Select })
				else
					fallback()
				end
			end, { "i", "s" }),
		})

		cmp.setup({
			preselect = types.cmp.PreselectMode.None,
			completion = {
				completeopt = "menu,menuone,noselect,noinsert",
			},
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
			},
			mapping = cmp_mappings,
		})
	end,
}
