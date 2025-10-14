return {
  'echasnovski/mini.nvim',
  config = function()
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Parenthesis
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup { n_lines = 500 }

    -- "gS" to toggle splitjoin on objects, arrays, etc.
    require('mini.splitjoin').setup()

    -- Movement helpers, for example ciq to change inside quotes, cib to change inside brackets, etc.
    require('mini.ai').setup()

    -- GitSigns
    require('mini.diff').setup {
      view = {
        signs = { add = ' ', change = '󰏫 ', delete = '󰆴 ' },
      },
      mappings = {
        -- Apply hunks inside a visual/operator region
        apply = 'gh',

        -- Reset hunks inside a visual/operator region
        reset = 'gH',

        -- Hunk range textobject to be used inside operator
        -- Works also in Visual mode if mapping differs from apply and reset
        textobject = 'gh',

        -- Go to hunk range in corresponding direction
        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
      },
    }

    -- Highlight colors and TODOs
    local hipatterns = require 'mini.hipatterns'
    hipatterns.setup {
      highlighters = {
        vim.cmd [[
            highlight MiniHipatternsFixme guifg=Black guibg=NvimLightRed gui=bold
            highlight MiniHipatternsHack guifg=Black guibg=NvimLightYellow gui=bold
            highlight MiniHipatternsTodo guifg=Black guibg=NvimLightCyan gui=bold
            highlight MiniHipatternsNote guifg=Black guibg=NvimLightGreen gui=bold
        ]],

        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = hipatterns.gen_highlighter.hex_color(),
      },
    }

    -- WhicihKey replacement
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
        { mode = 'n', keys = '<leader>a', desc = '[A]i' },
        { mode = 'n', keys = '<leader>b', desc = '[B]uffers' },
        { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
        { mode = 'n', keys = '<leader>cp', desc = '[C]ode PHP' },
        { mode = 'n', keys = '<leader>e', desc = '[E]ditor' },
        { mode = 'n', keys = '<leader>es', desc = '[S]pelling' },
        { mode = 'n', keys = '<leader>esl', desc = '[L]anguage' },
        { mode = 'n', keys = '<leader>g', desc = '[G]it' },
        { mode = 'n', keys = '<leader>l', desc = '[L]aravel' },
        { mode = 'n', keys = '<leader>L', desc = '[L]aravel' },
        { mode = 'n', keys = '<leader>r', desc = '[R]equests' },
        { mode = 'n', keys = '<leader>s', desc = '[S]earch' },
        { mode = 'n', keys = '<leader>t', desc = '[T]est' },
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
