return {
  'stevearc/oil.nvim',
  enabled = false,
  keys = {
    {
      '-',
      '<CMD>Oil<CR>',
      mode = { 'n' },
      desc = 'Open parent directory',
    },
  },
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
      natural_order = true,
      -- This function defines what will never be shown, even when `show_hidden` is set
      is_always_hidden = function(name, bufnr)
        local ignored_files = {}
        table.insert(ignored_files, '.git')
        table.insert(ignored_files, 'node_modules')
        table.insert(ignored_files, '.idea')
        table.insert(ignored_files, '.DS_Store')
        return vim.tbl_contains(ignored_files, name)
      end,
    },
    win_options = {
      wrap = true,
      winblend = 0,
    },
    keymaps = {
      ['<C-c>'] = false,
      ['q'] = 'actions.close',
    },
  },
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}
