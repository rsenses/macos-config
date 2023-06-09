return {
	"rebelot/kanagawa.nvim",
	lazy = false,
	name = "kanagawa",
	config = function()
		-- Kanagawa
		vim.o.background = "dark"

		require("kanagawa").setup({
			transparent = true, -- do not set background color
		})

		-- setup must be called before loading
		vim.cmd("colorscheme kanagawa")
	end,
}
