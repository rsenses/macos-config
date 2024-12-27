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
      quickfile = { enabled = true },
      statuscolumn = { enabled = false },
      words = { enabled = false },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
    },
    keys = {
      {
        '<leader>bd',
        function()
          Snacks.bufdelete()
        end,
        desc = 'Delete Buffer',
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
        '<leader>gf',
        function()
          Snacks.lazygit.log_file()
        end,
        desc = 'Lazygit Current File History',
      },
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gl',
        function()
          Snacks.lazygit.log()
        end,
        desc = 'Lazygit Log (cwd)',
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
        '<leader>cR',
        function()
          Snacks.rename.rename_file()
        end,
        desc = '[R]ename File',
      },
    },
  },
}
