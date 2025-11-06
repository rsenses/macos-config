return {
  'adibhanna/laravel.nvim',
  enabled = false,
  dependencies = {
    { 'MunifTanjim/nui.nvim', enabled = false },
    { 'nvim-lua/plenary.nvim', enabled = false },
  },
  cmd = { 'Artisan', 'Composer', 'Laravel' },
  ft = { 'blade', 'php' },
  keys = {
    { '<leader>la', ':Artisan<cr>', desc = 'Laravel Artisan' },
    { '<leader>lc', ':Composer<cr>', desc = 'Composer' },
    { '<leader>lr', ':LaravelRoute<cr>', desc = 'Laravel Routes' },
    { '<leader>lm', ':LaravelMake<cr>', desc = 'Laravel Make' },
  },
  event = { 'VeryLazy' },
  config = function()
    require('laravel').setup {
      notifications = false, -- No notifications when Laravel project is detected
    }
  end,
}
