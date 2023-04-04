return {
    'echasnovski/mini.nvim',
    lazy = false,
    version = '*',
    dependencies = {
        {
            'echasnovski/mini.splitjoin',
            version = false
        },
        'lewis6991/gitsigns.nvim',
    },
    config = function()
        require('gitsigns').setup()
        require('mini.comment').setup()
        require('mini.pairs').setup()
        require('mini.splitjoin').setup()
        require('mini.surround').setup()
    end,
}
