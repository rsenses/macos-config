return {
  'ricardoramirezr/blade-nav.nvim',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
  ft = { 'blade', 'php' }, -- optional, improves startup time
  opts = {
    close_tag_on_complete = true, -- default: true
  },
}
