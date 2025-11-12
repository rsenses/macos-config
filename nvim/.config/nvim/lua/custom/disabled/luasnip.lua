-- Autocompletion
return {
  'L3MON4D3/LuaSnip',
  build = 'make install_jsregexp',
  event = 'InsertEnter',
  enabled = false,
  config = function()
    local ls = require 'luasnip'

    -- Opcional: integra con vim.snippet (ok)
    vim.snippet.expand = ls.lsp_expand
    vim.snippet.active = function(filter)
      filter = filter or {}
      filter.direction = filter.direction or 1
      return (filter.direction == 1) and ls.expand_or_jumpable() or ls.jumpable(filter.direction)
    end
    vim.snippet.jump = function(direction)
      if direction == 1 then
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      else
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end
    end
    vim.snippet.stop = ls.unlink_current

    -- === LuaSnip setup ===
    ls.config.set_config {
      history = true,
      updateevents = 'TextChanged,TextChangedI',
      override_builtin = true,
      enable_autosnippets = true,
    }

    -- 1) Usa lazy_load (más robusto con lazy.nvim)
    require('luasnip.loaders.from_lua').lazy_load {
      paths = { vim.fn.stdpath 'config' .. '/after/snippets' },
    }

    -- (Opcional) VSCode-style (si usas friendly-snippets)
    -- require("luasnip.loaders.from_vscode").lazy_load()

    -- 2) Keymaps: expr para no tragarse la tecla
    vim.keymap.set({ 'i', 's' }, '<C-e>', function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true, desc = 'LuaSnip next choice' })

    vim.keymap.set({ 'i', 's' }, '<C-j>', function()
      if ls.expand_or_jumpable() then
        return '<Plug>luasnip-expand-or-jump'
      else
        return '<C-j>' -- no romper el flujo si no hay snippet
      end
    end, { expr = true, silent = true, desc = 'LuaSnip expand/jump' })

    vim.keymap.set({ 'i', 's' }, '<C-k>', function()
      if ls.jumpable(-1) then
        return '<Plug>luasnip-jump-prev'
      else
        return '<C-k>'
      end
    end, { expr = true, silent = true, desc = 'LuaSnip jump back' })
  end,
}
