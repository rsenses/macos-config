return {
	{
		"lewis6991/gitsigns.nvim",
		lazy = false,
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("gitsigns").setup({
				sign_priority = 20,
			})
		end,
	},
	{
		"mbbill/undotree",
		cmd = { "UndotreeShow", "UndotreeToggle", "UndotreeHide", "UndotreeFocus" },
	},
	{
		"windwp/nvim-ts-autotag",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-ts-autotag").setup({
				filetypes = {
					"html",
					"javascript",
					"typescript",
					"javascriptreact",
					"typescriptreact",
					"svelte",
					"vue",
					"tsx",
					"jsx",
					"rescript",
					"xml",
					"php",
					"markdown",
					"astro",
					"glimmer",
					"handlebars",
					"hbs",
					"blade",
				},
			})
		end,
		lazy = true,
		event = "VeryLazy",
	},
	-- {
	-- 	"github/copilot.vim",
	-- 	lazy = false,
	-- 	config = function()
	-- 		vim.g.copilot_no_tab_map = true
	-- 		vim.g.copilot_assume_mapped = true
	-- 	end,
	-- },
	{
		"exafunction/codeium.vim",
		lazy = false,
		config = function()
			vim.g.codeium_disable_bindings = 1
			vim.keymap.set("i", "<C-Space>", function()
				return vim.fn["codeium#Accept"]()
			end, { expr = true })
			vim.keymap.set("i", "<C-n>", function()
				return vim.fn["codeium#CycleCompletions"](1)
			end, { expr = true })
			vim.keymap.set("i", "<C-p>", function()
				return vim.fn["codeium#CycleCompletions"](-1)
			end, { expr = true })
			vim.keymap.set("i", "<C-e>", function()
				return vim.fn["codeium#Clear"]()
			end, { expr = true })
			vim.g.codeium_no_map_tab = true
		end,
	},
	{
		"tpope/vim-fugitive",
		lazy = false,
	},
	{
		"sheerun/vim-polyglot",
		lazy = false,
	},
	{
		"numToStr/Comment.nvim",
		lazy = false,
		dependencies = "JoosepAlviste/nvim-ts-context-commentstring",
		config = function()
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},
}
