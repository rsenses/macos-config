-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`. This is equivalent to the following lua:
--    require('gitsigns').setup({ ... })
--
-- See `:help gitsigns` to understand what the configuration keys do
-- Adds git related signs to the gutter, as well as utilities for managing changes
return {
  'lewis6991/gitsigns.nvim',
  config = function()
    require('gitsigns').setup {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    }

    -- ==================
    --     Statusline
    -- ==================
    local init_group = vim.api.nvim_create_augroup('reset_group', {
      clear = false,
    })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'FocusGained' }, {
      desc = 'git branch and LSP errors for the statusline',
      callback = function()
        if vim.fn.isdirectory '.git' ~= 0 then
          -- always runs in the current directory, rather than in the buffer's directory
          local branch = vim.fn.system "git branch --show-current | tr -d '\n'"
          vim.b.branch_name = '  ' .. branch .. ' '
        end

        local num_errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        -- if there are any errors only show the error count, don't include the number of warnings
        if num_errors > 0 then
          vim.b.errors = '  ' .. num_errors .. ' '
          return
        end
        -- otherwise show amount of warnings, or nothing if there aren't any
        local num_warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        if num_warnings > 0 then
          vim.b.errors = '  ' .. num_warnings .. ' '
          return
        end
        vim.b.errors = ''
      end,
      group = init_group,
    })

    vim.opt.statusline =
      [[%#PmenuSel#%{get(b:, "branch_name", "")}%#LineNr# %f %m %= %#CursorColumn# %{get(b:, "errors", "")} %y %{&fileencoding?&fileencoding:&encoding} %l:%c]]
  end,
}
