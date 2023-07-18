return {
    'echasnovski/mini.nvim',
    lazy = false,
    version = '*',
    dependencies = {
        {
            'echasnovski/mini.splitjoin',
            version = false
        },
    },
    config = function()
        -- require('mini.comment').setup()
        require('mini.pairs').setup()
        require('mini.splitjoin').setup()
        require('mini.surround').setup()
    end,
}
