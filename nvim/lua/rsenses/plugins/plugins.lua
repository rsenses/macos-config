return {
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
    { "github/copilot.vim", lazy = false },
    {
        "sheerun/vim-polyglot",
        lazy = false,
    },
}
