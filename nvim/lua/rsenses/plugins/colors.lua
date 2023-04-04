return {
    "rebelot/kanagawa.nvim",
    lazy = false,
    name = "kanagawa",
    config = function()
        -- Kanagawa
        vim.o.background = "dark"

        -- setup must be called before loading
        vim.cmd("colorscheme kanagawa")
    end,
}
