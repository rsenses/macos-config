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
				-- your config
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
}
