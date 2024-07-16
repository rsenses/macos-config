return {
  'echasnovski/mini.nvim',
  config = function()
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup { n_lines = 500 }

    -- "gS" to toggle splitjoin on objects, arrays, etc.
    require('mini.splitjoin').setup()

    -- Notifications
    require('mini.notify').setup {
      lsp_progress = {
        -- Whether to enable showing
        enable = false,
      },
    }
    vim.notify = require('mini.notify').make_notify()

    -- Autopairs
    require('mini.pairs').setup()

    -- Tabline (show buffers on top)
    require('mini.tabline').setup()

    -- Highlight colors and TODOs
    local hipatterns = require 'mini.hipatterns'
    hipatterns.setup {
      highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = hipatterns.gen_highlighter.hex_color(),
      },
    }

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    statusline.setup {
      set_vim_settings = true,
    }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    local miniclue = require 'mini.clue'
    miniclue.setup {
      triggers = {
        -- Leader triggers
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },

        -- Built-in completion
        { mode = 'i', keys = '<C-x>' },

        -- `g` key
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },

        -- Marks
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = '`' },
        { mode = 'x', keys = "'" },
        { mode = 'x', keys = '`' },

        -- Registers
        { mode = 'n', keys = '"' },
        { mode = 'x', keys = '"' },
        { mode = 'i', keys = '<C-r>' },
        { mode = 'c', keys = '<C-r>' },

        -- Window commands
        { mode = 'n', keys = '<C-w>' },

        -- `z` key
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },

        -- Brackets
        { mode = 'n', keys = '[' },
        { mode = 'n', keys = ']' },
        { mode = 'x', keys = '[' },
        { mode = 'x', keys = ']' },
      },

      clues = {
        -- Enhance this by adding descriptions for <Leader> mapping groups
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),

        -- Descriptions
        { mode = 'n', keys = '<leader>b', desc = '[B]uffers' },
        { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
        { mode = 'n', keys = '<leader>d', desc = '[D]ocument' },
        { mode = 'n', keys = '<leader>g', desc = '[G]it' },
        { mode = 'n', keys = '<leader>h', desc = '[H]arpoon' },
        { mode = 'n', keys = '<leader>l', desc = '[L]aravel' },
        { mode = 'n', keys = '<leader>s', desc = '[S]earch' },
        { mode = 'n', keys = '<leader>w', desc = '[W]indows' },
      },

      window = {
        config = {
          anchor = 'SE' --[[ bottom right ]],
          row = 'auto',
          col = 'auto',
          width = 'auto',
        },
        delay = 500,
        -- Keys to scroll inside the clue window
        scroll_down = '<C-n>',
        scroll_up = '<C-p>',
      },
    }
  end,
}
