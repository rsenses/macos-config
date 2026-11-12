vim.cmd 'packadd cfilter'
vim.cmd.packadd 'nvim.difftool'

-- `vim.pack` has no lazy.nvim-style `build` field. Update Treesitter parsers
-- after an explicit plugin update instead, and expose the reviewable native
-- package update flow without doing network work at startup.
local pack_update_group = vim.api.nvim_create_augroup('PackUpdateHooks', { clear = true })
vim.api.nvim_create_autocmd('PackChanged', {
  group = pack_update_group,
  callback = function(ev)
    local data = ev.data
    if data.spec.name ~= 'nvim-treesitter' or data.kind ~= 'update' then
      return
    end

    vim.schedule(function()
      if vim.fn.exists ':TSUpdate' == 2 then
        vim.cmd 'TSUpdate'
      end
    end)
  end,
})

vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Review and update native packages' })

vim.pack.add({
  -- 'https://github.com/tpope/vim-dadbod',
  -- 'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/mistweaverco/kulala.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/esmuellert/codediff.nvim',
  'https://github.com/MattiasMTS/pjollrig.nvim',
  'https://github.com/nvim-mini/mini.nvim',
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
    version = 'main',
  },
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/windwp/nvim-ts-autotag',
  {
    src = 'https://github.com/rose-pine/neovim',
    name = 'rose-pine',
  },
  'https://github.com/stevearc/conform.nvim',
  -- 'https://github.com/barrettruth/canola.nvim',
  'https://github.com/supermaven-inc/supermaven-nvim',
  'https://github.com/rachartier/tiny-cmdline.nvim',
  'https://github.com/kevinhwang91/nvim-hlslens',
  -- 'https://github.com/abecodes/tabout.nvim',
}, {
  confirm = false,
  load = true,
})

-- TABOUT
-- require('tabout').setup {}

-- HLSLENS
require('hlslens').setup()

-- TINY CMDLINE
vim.g.tiny_cmdline = {
  width = { value = '70%' },
}

-- COLORSCHEMA
vim.o.background = 'light'

-- ROSEPINE
require('rose-pine').setup {
  variant = 'dawn', -- auto, main, moon, or dawn
  dark_variant = 'main',
  bold_vert_split = false,
  dim_nc_background = false,
  disable_background = false,
  disable_float_background = false,
  styles = {
    bold = true,
    italic = true,
    transparency = false,
  },
}

vim.cmd 'colorscheme rose-pine'

-- Command line y Winbar del mismo color que CursorLine
vim.api.nvim_set_hl(0, 'MsgArea', { link = 'CursorLine' })
vim.api.nvim_set_hl(0, 'WinBar', { link = 'CursorLine' })
-- END COLORSCHEMA

require 'custom.format'

-- KULALA
require('kulala').setup {
  global_keymaps = true,
  global_keymaps_prefix = '<leader>r',
  kulala_keymaps_prefix = '',
  treesitter = {
    enable = false,
  },
}
-- END KULALA

require 'custom.mini'
require 'custom.codediff'
require 'custom.pjollrig'

-- OIL
-- require('oil').setup {
--   default_file_explorer = true,
--   delete_to_trash = true,
--   skip_confirm_for_simple_edits = true,
--   lsp_file_methods = {
--     enabled = true,
--     timeout_ms = 1000,
--     autosave_changes = true,
--   },
--   view_options = {
--     show_hidden = true,
--     natural_order = true,
--     is_always_hidden = function(name)
--       local ignored_files = { '.git', 'node_modules', '.idea', '.DS_Store' }
--       return vim.tbl_contains(ignored_files, name)
--     end,
--   },
--   win_options = {
--     wrap = true,
--     winblend = 0,
--   },
--   keymaps = {
--     ['<C-c>'] = false,
--     q = 'actions.close',
--   },
-- }
--
-- vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
-- END OIL

-- MARKDOWN
require('render-markdown').setup {
  file_types = { 'markdown' },
  completions = { lsp = { enabled = true } },
}
-- END MARKDOWN

-- SUPERMAVEN
require('supermaven-nvim').setup {
  keymaps = {
    clear_suggestion = '<C-e>',
    accept_word = '<C-l>',
  },
  ignore_filetypes = { cpp = true },
  color = {
    suggestion_color = '#888888',
    cterm = 244,
  },
  log_level = 'info',
  disable_inline_completion = false,
  disable_keymaps = false,
}
-- END SUPERMAVEN

require 'custom.treesitter'

-- CLEAN Pack UNUSED PLUGINS
local function pack_clean()
  local active_plugins = {}
  local unused_plugins = {}

  for _, plugin in ipairs(vim.pack.get()) do
    active_plugins[plugin.spec.name] = plugin.active
  end

  for _, plugin in ipairs(vim.pack.get()) do
    if not active_plugins[plugin.spec.name] then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end

  if #unused_plugins == 0 then
    print 'No unused plugins.'
    return
  end

  local choice = vim.fn.confirm('Remove unused plugins?', '&Yes\n&No', 2)
  if choice == 1 then
    vim.pack.del(unused_plugins)
  end
end

vim.keymap.set('n', '<leader>pc', pack_clean, { desc = 'Clean plugins' })

-- update packs
vim.keymap.set('n', '<leader>pu', function()
  vim.pack.update()
end, { desc = 'Update plugins' })
