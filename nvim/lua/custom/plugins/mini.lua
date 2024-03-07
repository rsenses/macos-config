return {
  'echasnovski/mini.nvim',
  config = function()
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup { n_lines = 500 }

    require('mini.indentscope').setup {
      -- Options which control scope computation
      options = {
        -- Whether to first check input line to be a border of adjacent scope.
        -- Use it if you want to place cursor on function header to get scope of
        -- its body.
        try_as_border = true,
      },
    }

    -- "gc" to comment visual regions/lines
    require('mini.comment').setup()

    -- Notifications
    require('mini.notify').setup {
      lsp_progress = {
        -- Whether to enable showing
        enable = false,
      },
    }
    vim.notify = require('mini.notify').make_notify()

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    statusline.setup()

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
