return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"nvim-treesitter/nvim-treesitter-context",
		"lukas-reineke/indent-blankline.nvim",
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		require("nvim-web-devicons").setup({})
		require("nvim-treesitter.configs").setup({
			-- A list of parser names, or "all"
			ensure_installed = { "help", "javascript", "typescript", "c", "lua", "rust", "php" },
			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,
			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
			auto_install = true,
			highlight = {
				-- `false` will disable the whole extension
				enable = true,
				-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
				-- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
				-- Using this option may slow down your editor, and you may see some duplicate highlights.
				-- Instead of true it can also be a list of languages
				-- additional_vim_regex_highlighting = { "html" },
				disable = { "html" },
			},
			indent = {
				enable = true,
			},
			context_commentstring = {
				enable = true,
			},
			autotag = {
				enable = true,
			},
		})

		require("indent_blankline").setup({
			space_char_blankline = " ",
			show_current_context = true,
			show_current_context_start = true,
		})
	end,
}
