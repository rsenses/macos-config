-- Autocompletion
return {
  'saghen/blink.cmp',
  version = '*',
  event = 'InsertEnter',
  dependencies = {
    { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    'zbirenbaum/copilot.lua',
    'giuxtaposition/blink-cmp-copilot',
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },

    snippets = {
      expand = function(snippet)
        require('luasnip').lsp_expand(snippet)
      end,
      active = function(filter)
        if filter and filter.direction then
          return require('luasnip').jumpable(filter.direction)
        end
        return require('luasnip').in_snippet()
      end,
      jump = function(direction)
        require('luasnip').jump(direction)
      end,
    },

    sources = {
      default = { 'lsp', 'path', 'luasnip', 'buffer', 'copilot' },
      providers = {
        copilot = {
          name = 'copilot',
          module = 'blink-cmp-copilot',
          score_offset = 100,
          async = true,
        },
      },
    },
  },
  opts_extend = { 'sources.default' },
}
