local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        dependencies = {
            {'nvim-lua/plenary.nvim'},
            {'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
        }
    },
    'folke/which-key.nvim',
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'nvim-treesitter/nvim-treesitter-context',
            'lukas-reineke/indent-blankline.nvim',
        },
    },
    'mbbill/undotree',
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-path'},
            {'saadparwaiz1/cmp_luasnip'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/cmp-nvim-lua'},

            -- Snippets
            {'L3MON4D3/LuaSnip'},
            {'rafamadriz/friendly-snippets'},

            -- Formatter
            {'jose-elias-alvarez/null-ls.nvim'},
        }
    },
    'github/copilot.vim',
    {
        'echasnovski/mini.nvim',
        version = '*',
        dependencies = {
            {
                'echasnovski/mini.splitjoin',
                version = false
            },
            'lewis6991/gitsigns.nvim',
        }
    },
    "sheerun/vim-polyglot",
    "rebelot/kanagawa.nvim",
})

