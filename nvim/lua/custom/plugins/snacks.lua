return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      indent = { enabled = true },
      animate = { enabled = false },
      bigfile = { enabled = false },
      dashboard = { example = 'doom' },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      scratch = { enabled = false },
      input = {},
      quickfile = { enabled = true },
      statuscolumn = { enabled = false },
      words = { enabled = false },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
      zen = { enabled = true },
      image = {
        enabled = true,
        doc = {
          -- Personally I set this to false, I don't want to render all the
          -- images in the file, only when I hover over them
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = false,
          -- only_render_image_at_cursor = vim.g.neovim_mode == "skitty" and false or true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          -- Sets the size of the image
          -- max_width = 60,
          max_width = vim.g.neovim_mode == 'skitty' and 20 or 60,
          max_height = vim.g.neovim_mode == 'skitty' and 10 or 30,
          -- max_height = 30,
          -- Apparently, all the images that you preview in neovim are converted
          -- to .png and they're cached, original image remains the same, but
          -- the preview you see is a png converted version of that image
          --
          -- Where are the cached images stored?
          -- This path is found in the docs
          -- :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
          -- For me returns `~/.cache/neobean/snacks/image`
          -- Go 1 dir above and check `sudo du -sh ./* | sort -hr | head -n 5`
        },
      },
      -- picker = {enabled = true},
    },
    keys = {
      {
        '<leader>bd',
        function()
          Snacks.bufdelete()
        end,
        desc = '[B]uffer [D]elete',
      },
      {
        '<leader>bp',
        function()
          Snacks.bufdelete.all()
        end,
        desc = '[B]uffer [P]urge',
      },
      {
        '<leader>gB',
        function()
          Snacks.gitbrowse()
        end,
        desc = 'Git Browse',
      },
      {
        '<leader>gb',
        function()
          Snacks.git.blame_line()
        end,
        desc = 'Git Blame Line',
      },
      {
        '<leader>eh',
        function()
          Snacks.notifier.show_history()
        end,
        desc = 'Notification [H]istory',
      },
      {
        '<leader>eu',
        function()
          Snacks.notifier.hide()
        end,
        desc = 'Dismiss All Notifications',
      },
      {
        '<leader>ez',
        function()
          Snacks.zen()
        end,
        desc = '[E]ditor [Z]en',
      },
      -- {
      --   '<leader>cR',
      --   function()
      --     Snacks.rename.rename_file()
      --   end,
      --   desc = '[R]ename File',
      -- },
      -- Picker
      -- {
      --   '<leader>.',
      --   function()
      --     Snacks.picker.recent()
      --   end,
      --   desc = 'Recent',
      -- },
      -- {
      --   '<leader><space>',
      --   function()
      --     Snacks.picker.smart()
      --   end,
      --   desc = 'Smart Find Files',
      -- },
      -- {
      --   '<leader>,',
      --   function()
      --     Snacks.picker.buffers {
      --       layout = {
      --         preset = 'ivy',
      --       },
      --       finder = 'buffers',
      --       format = 'buffer',
      --       hidden = false,
      --       unloaded = true,
      --       current = true,
      --       sort_lastused = true,
      --       win = {
      --         input = {
      --           keys = {
      --             ['<c-d>'] = { 'bufdelete', mode = { 'n', 'i' } },
      --             ['dd'] = { 'bufdelete', mode = { 'n' } },
      --           },
      --         },
      --       },
      --     }
      --   end,
      --   desc = 'Buffers',
      -- },
      -- {
      --   '<leader>sg',
      --   function()
      --     Snacks.picker.grep()
      --   end,
      --   desc = 'Grep',
      -- },
      -- {
      --   '<leader>sh',
      --   function()
      --     Snacks.picker.help()
      --   end,
      --   desc = 'Help Pages',
      -- },
      -- {
      --   '<leader>sk',
      --   function()
      --     Snacks.picker.keymaps()
      --   end,
      --   desc = 'Keymaps',
      -- },
      -- {
      --   '<leader>sw',
      --   function()
      --     Snacks.picker.grep_word()
      --   end,
      --   desc = 'Visual selection or word',
      --   mode = { 'n', 'x' },
      -- },
      -- {
      --   '<leader>sd',
      --   function()
      --     Snacks.picker.diagnostics()
      --   end,
      --   desc = 'Diagnostics',
      -- },
      -- {
      --   '<leader>sD',
      --   function()
      --     Snacks.picker.diagnostics_buffer()
      --   end,
      --   desc = 'Buffer Diagnostics',
      -- },
      -- {
      --   '<leader>sr',
      --   function()
      --     Snacks.picker.resume()
      --   end,
      --   desc = 'Resume',
      -- },
      -- {
      --   '<leader>en',
      --   function()
      --     Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      --   end,
      --   desc = 'Find Config File',
      -- },
      -- {
      --   '<leader>/',
      --   function()
      --     Snacks.picker.grep_buffers()
      --   end,
      --   desc = 'Grep Open Buffers',
      -- },
      -- {
      --   '<leader>sp',
      --   function()
      --     Snacks.picker.registers()
      --   end,
      --   desc = 'Registers',
      -- },
      -- {
      --   'gd',
      --   function()
      --     Snacks.picker.lsp_definitions()
      --   end,
      --   desc = 'Goto Definition',
      -- },
      -- {
      --   'gr',
      --   function()
      --     Snacks.picker.lsp_references()
      --   end,
      --   nowait = true,
      --   desc = 'References',
      -- },
      -- {
      --   'gI',
      --   function()
      --     Snacks.picker.lsp_implementations()
      --   end,
      --   desc = 'Goto Implementation',
      -- },
      -- {
      --   '<leader>sD',
      --   function()
      --     Snacks.picker.lsp_type_definitions()
      --   end,
      --   desc = 'Goto T[y]pe Definition',
      -- },
      -- {
      --   '<leader>ss',
      --   function()
      --     Snacks.picker.lsp_symbols()
      --   end,
      --   desc = 'LSP Symbols',
      -- },
      -- {
      --   '<leader>sS',
      --   function()
      --     Snacks.picker.lsp_workspace_symbols()
      --   end,
      --   desc = 'LSP Workspace Symbols',
      -- },
    },
  },
}
