return {
  'nvim-mini/mini.nvim',
  version = false,
  event = 'VeryLazy',
  config = function()
    require('mini.extra').setup()

    local mini_icons = require 'mini.icons'
    mini_icons.setup()
    vim.api.nvim_create_autocmd('LspAttach', {
      once = true,
      desc = 'MiniIcons: tweak LSP kinds lazily to avoid loading vim.lsp on startup',
      callback = function()
        mini_icons.tweak_lsp_kind()
      end,
    })

    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Parenthesis
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup { n_lines = 500 }

    -- "gS" to toggle splitjoin on objects, arrays, etc.
    require('mini.splitjoin').setup()

    -- Movement helpers, for example ciq to change inside quotes, cib to change inside brackets, etc.
    require('mini.ai').setup()

    -- Picker
    -- Seleccionas con C-x o C-a para todos y Alt-Enter para mandar a quickfix
    local pick = require 'mini.pick'
    pick.setup()

    -- Smart Find Files (usa fd si está disponible)
    vim.keymap.set('n', '<leader><leader>', function()
      local opts
      if vim.fn.executable 'fd' == 1 then
        opts = {
          source = {
            cwd = vim.loop.cwd(),
            exec = { 'fd', '--type', 'f', '--hidden', '--exclude', '.git', '--exclude', 'vendor', '--exclude', 'node_modules' },
          },
        }
      end
      pick.builtin.files(opts)
    end, { desc = 'Smart Find Files' })
    -- Grep (contenido)
    vim.keymap.set('n', '<leader>sg', '<Cmd>Pick grep_live<CR>', { desc = 'Grep' })
    -- Grep palabra o selección visual
    vim.keymap.set({ 'n', 'x' }, '<leader>sw', '<Cmd>Pick grep pattern="<cword>"<CR>', { desc = 'Visual selection or word' })
    -- Diagnostics (workspace y buffer)
    vim.keymap.set('n', '<leader>sD', '<Cmd>Pick diagnostic scope="all"<CR>', { desc = 'Diagnostics' })
    vim.keymap.set('n', '<leader>sd', '<Cmd>Pick diagnostic scope="current"<CR>', { desc = 'Buffer Diagnostics' })
    -- Registers
    vim.keymap.set('n', '<leader>sr', '<Cmd>Pick registers<CR>', { desc = 'Registers' })
    -- LSP: referencias / definiciones / símbolos
    vim.keymap.set('n', 'grr', '<Cmd>Pick lsp scope="references"<CR>', { nowait = true, desc = 'References' })
    -- vim.keymap.set('n', 'gd', extra.pickers.lsp_definitions, { desc = 'Goto Definition' })
    vim.keymap.set('n', '<leader>ss', '<Cmd>Pick lsp scope="document_symbol"<CR>', { desc = 'LSP Symbols' })

    -- Buff remove without destroying the window
    local bufremove = require 'mini.bufremove'
    vim.keymap.set('n', '<leader>bd', bufremove.delete, { desc = '[B]uffer [D]elete' })
    vim.keymap.set('n', '<leader>bp', function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          bufremove.delete(buf)
        end
      end
    end, { desc = '[B]uffer [P]urge (all)' })
    vim.keymap.set('n', '<leader>bo', function()
      local current = vim.api.nvim_get_current_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and buf ~= current then
          bufremove.delete(buf)
        end
      end
    end, { desc = '[B]uffer delete [O]thers' })

    -- Dashboard
    local starter = require 'mini.starter'
    starter.setup {
      header = table.concat({
        '   _       _        _           ',
        ' _| |_____| |_  ___| |__  _   _ ',
        "|_   _|_  / __|/ __| '_ \\| | | |",
        '  |_|  /__\\__ \\ (__| | | | |_| |',
        '           |___/\\___|_| |_|\\__, |',
        '                            |___/ ',
      }, '\n'),
      items = {
        starter.sections.recent_files(10, true),
        { name = 'Edit config', action = 'e $MYVIMRC', section = 'Actions' },
        { name = 'Find files', action = 'Pick files', section = 'Actions' },
      },
      footer = function()
        -- Si quieres un mini "git status" en el footer (ligero):
        local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1] or ''
        return (root ~= '' and ('Git: ' .. vim.fn.fnamemodify(root, ':t'))) or ''
      end,
    }

    -- Mini notify
    require('mini.notify').setup()

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
    vim.cmd [[
      highlight MiniHipatternsFixme guifg=Black guibg=NvimLightRed gui=bold
      highlight MiniHipatternsHack guifg=Black guibg=NvimLightYellow gui=bold
      highlight MiniHipatternsTodo guifg=Black guibg=NvimLightCyan gui=bold
      highlight MiniHipatternsNote guifg=Black guibg=NvimLightGreen gui=bold
    ]]
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

    -- Mini completions
    require('mini.completion').setup {
      mappings = {
        -- Force two-step/fallback completions
        force_twostep = '<C-Space>',
        force_fallback = '<A-Space>',

        -- Scroll info/signature window down/up. When overriding, check for
        -- conflicts with built-in keys for popup menu (like `<C-u>`/`<C-o>`
        -- for 'completefunc'/'omnifunc' source function; or `<C-n>`/`<C-p>`).
        scroll_down = '<C-n>',
        scroll_up = '<C-p>',
      },
    }

    -- Snippets
    local gen_loader = require('mini.snippets').gen_loader
    require('mini.snippets').setup {
      snippets = {
        -- Load custom file with global snippets first (adjust for Windows)
        gen_loader.from_file '~/.config/nvim/snippets/global.json',

        -- Load snippets based on current language by reading files from
        -- "snippets/" subdirectories from 'runtimepath' directories.
        gen_loader.from_lang {
          extend = { blade = { 'php', 'html' } }, -- 🔹 blade hereda de php y html
        },
      },
      mappings = {
        expand = '<C-j>', -- expande snippet (y primer salto)
        jump_next = '<Tab>', -- siguiente placeholder
        jump_prev = '<S-Tab>', -- placeholder anterior
        stop = '<C-e>',
      },
    }
    require('mini.snippets').start_lsp_server()

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
        { mode = 'n', keys = '<leader>b', desc = '[B]uffers' },
        { mode = 'n', keys = '<leader>c', desc = '[C]ode' },
        { mode = 'n', keys = '<leader>cp', desc = '[C]ode PHP' },
        { mode = 'n', keys = '<leader>e', desc = '[E]ditor' },
        { mode = 'n', keys = '<leader>es', desc = '[S]pelling' },
        { mode = 'n', keys = '<leader>esl', desc = '[L]anguage' },
        { mode = 'n', keys = '<leader>g', desc = '[G]it' },
        { mode = 'n', keys = '<leader>h', desc = '[H]arpoon' },
        { mode = 'n', keys = '<leader>l', desc = '[L]aravel' },
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
