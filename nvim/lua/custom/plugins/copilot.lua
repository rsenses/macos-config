-- Autocompletion
-- return {
--   'zbirenbaum/copilot.lua',
--   cmd = 'Copilot',
--   event = 'InsertEnter',
--   opts = {
--     -- suggestion = { enabled = false },
--     -- panel = { enabled = false },
--     -- filetypes = {
--     --   markdown = true,
--     --   help = false,
--     -- },
--   },
-- }
return {
  'github/copilot.vim',
  event = 'InsertEnter',
  config = function()
    vim.keymap.set('i', '<Tab>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
    })
    vim.keymap.set('i', '<M-n>', 'copilot#Next()', {
      expr = true,
      replace_keycodes = false,
    })
    vim.keymap.set('i', '<M-p>', 'copilot#Previous()', {
      expr = true,
      replace_keycodes = false,
    })
    vim.keymap.set('i', '<C-e>', 'copilot#Dismiss()', {
      expr = true,
      replace_keycodes = false,
    })
    -- accept next word with alt right arrow
    vim.keymap.set('i', '<C-Right>', 'copilot#Accept("\\<Right>")', {
      expr = true,
      replace_keycodes = false,
    })
    -- accept next line with alt down arrow
    vim.keymap.set('i', '<C-Down>', 'copilot#Accept("\\<Down>")', {
      expr = true,
      replace_keycodes = false,
    })
    -- Disable Tab key mapping to prevent conflicts
    vim.g.copilot_no_tab_map = true

    -- -- Enable Copilot for specific file types
    -- vim.g.copilot_filetypes = {
    --   ['*'] = false,
    --   python = true,
    --   javascript = true,
    --   lua = true,
    -- }
  end,
}
