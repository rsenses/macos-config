return {
  'stevearc/oil.nvim',
  opts = {
    delete_to_trash = true,
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
      -- This function defines what will never be shown, even when `show_hidden` is set
      is_always_hidden = function(name, bufnr)
        local ignored_files = {}
        table.insert(ignored_files, '.git')
        table.insert(ignored_files, 'vendor')
        table.insert(ignored_files, 'node_modules')
        table.insert(ignored_files, '.idea')
        table.insert(ignored_files, '.DS_Store')
        return vim.tbl_contains(ignored_files, name)
      end,
    },
  },
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}
