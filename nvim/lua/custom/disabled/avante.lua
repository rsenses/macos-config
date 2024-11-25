return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    -- add any opts here
    provider = 'copilot',
    auto_suggestions_provider = 'copilot',
  },
  build = 'make',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    {
      'stevearc/dressing.nvim',
      opts = {
        input = {
          relative = 'editor',
          prefer_width = 0.4,
        },
      },
    },
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'zbirenbaum/copilot.lua', -- for providers='copilot'
  },
}
