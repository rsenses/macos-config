return {
  'monkoose/neocodeium',
  event = 'VeryLazy',
  config = function()
    local neocodeium = require 'neocodeium'
    neocodeium.setup {
      filetypes = {
        TelescopePrompt = false,
        ['dap-repl'] = false,
      },
    }
    vim.keymap.set('i', '<C-y>', neocodeium.accept)
    vim.keymap.set('i', '<C-x>', neocodeium.clear)
    vim.keymap.set('i', '<C-]>', neocodeium.cycle)
    -- codeium chat
    vim.keymap.set('n', '<leader>cc', ':NeoCodeium chat<cr>', { desc = 'Codeium Chat' })
  end,
}
