-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin
-- Fuzzy Finder (files, lsp, etc)
return {
  'nvim-telescope/telescope.nvim',
  lazy = false,
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for install instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },

    -- Useful for getting pretty icons, but requires special font.
    --  If you already have a Nerd Font, or terminal set up with fallback fonts
    --  you can enable this
    { 'nvim-tree/nvim-web-devicons' },
    { 'mollerhoj/telescope-recent-files.nvim' },
  },
  config = function()
    -- Telescope is a fuzzy finder that comes with a lot of different things that
    -- it can fuzzy find! It's more than just a "file finder", it can search
    -- many different aspects of Neovim, your workspace, LSP, and more!
    --
    -- The easiest way to use telescope, is to start by doing something like:
    --  :Telescope help_tags
    --
    -- After running this command, a window will open up and you're able to
    -- type in the prompt window. You'll see a list of help_tags options and
    -- a corresponding preview of the help.
    --
    -- Two important keymaps to use while in telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      pickers = {
        buffers = {
          theme = 'ivy',
          sort_mru = true,
          sort_lastused = true,
          initial_mode = 'normal',
        },
      },
      defaults = {
        -- path_display = { 'smart' },
        file_ignore_patterns = {
          '.git/.*',
          '.cache',
          '%.o',
          '%.a',
          '%.out',
          '%.class',
          '%.pdf',
          '%.mkv',
          '%.mp4',
          '%.zip',
          '.elixir_ls/*',
          'deps/*',
          '_build/',
        },
        mappings = {
          i = {
            ['<c-d>'] = require('telescope.actions').delete_buffer,
            ['<c-t>'] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist,
          },
          n = {
            ['dd'] = require('telescope.actions').delete_buffer,
            ['q'] = require('telescope.actions').close,
          },
        },
      },
    }

    -- Enable telescope extensions, if they are installed
    require('telescope').load_extension 'fzf'
    require('telescope').load_extension 'recent-files'
    require('telescope').load_extension 'yank_history'

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>st', builtin.builtin, { desc = '[S]earch select [T]elescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<space>sg', require 'custom.plugins.telescope.multi-ripgrep', { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>,', function()
      require('telescope.builtin').buffers {}
    end, { desc = '[] Find existing buffers' })
    vim.keymap.set('n', '<leader>en', function()
      require('telescope.builtin').find_files {
        cwd = vim.fn.stdpath 'config',
      }
    end, { desc = '[N]vim configuration' })
    vim.keymap.set('n', '<leader>sp', function()
      require('telescope').extensions.yank_history.yank_history {}
    end, { desc = '[P]aste Yank History' })
    vim.keymap.set('n', '<leader><leader>', function()
      require('telescope').extensions['recent-files'].recent_files { hidden = true }
    end, { noremap = true, silent = true, desc = '[S]earch files' })
    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })
  end,
}
