return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "nvim-treesitter/nvim-treesitter-context",
            "lukas-reineke/indent-blankline.nvim",
        },
    },
    "mbbill/undotree",
    "github/copilot.vim",
    "tpope/vim-sleuth",
    "sheerun/vim-polyglot",
}
