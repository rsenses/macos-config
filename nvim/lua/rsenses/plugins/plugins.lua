return {
    {
        'lewis6991/gitsigns.nvim',
        lazy = false,
        dependencies = 'nvim-lua/plenary.nvim',
        config = function()
            require('gitsigns').setup({
                sign_priority = 20,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = true,
        build = ":TSUpdate",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "nvim-treesitter/nvim-treesitter-context",
            "lukas-reineke/indent-blankline.nvim",
        },
    },
    {
        "mbbill/undotree",
        cmd = { "UndotreeShow", "UndotreeToggle", "UndotreeHide", "UndotreeFocus" },
    },
    {
        "github/copilot.vim",
        lazy = false,
        config = function()
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_assume_mapped = true
        end
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
