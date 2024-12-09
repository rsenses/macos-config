-- Copilot
-- return {
--   'github/copilot.vim',
--   event = 'InsertEnter',
--   init = function()
--     vim.g.copilot_no_tab_map = true
--     vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
--     -- Accept suggestion with <C-y>
--     vim.keymap.set('i', '<C-y>', 'copilot#Accept()', {
--       expr = true,
--       replace_keycodes = false,
--     })
--     -- Dismiss suggestion with <C-e>
--     vim.keymap.set('i', '<C-e>', 'copilot#Dismiss()', {
--       expr = true,
--       replace_keycodes = false,
--     })
--     -- Next suggestion with <C-j>
--     vim.keymap.set('i', '<C-j>', 'copilot#Next()', {
--       expr = true,
--       replace_keycodes = false,
--     })
--     -- Previous suggestion with <C-k>
--     vim.keymap.set('i', '<C-k>', 'copilot#Prev()', {
--       expr = true,
--       replace_keycodes = false,
--     })
--   end,
-- }
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  build = ':Copilot auth',
  event = 'InsertEnter',
  dependencies = {
    {
      'zbirenbaum/copilot-cmp',
      config = function()
        require('copilot_cmp').setup()
      end,
    },
  },
  config = function()
    require('copilot').setup {
      suggestion = {
        enabled = false,
        -- auto_trigger = true,
        -- keymap = {
        --   accept = '<C-y>',
        --   next = '<C-j>',
        --   prev = '<C-k>',
        --   dismiss = '<C-e>',
        -- },
      },
      panel = {
        enabled = false,
      },
      filetypes = {
        markdown = true,
        help = false,
      },
    }
  end,
}
