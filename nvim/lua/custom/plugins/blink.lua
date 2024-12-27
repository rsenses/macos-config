-- Autocompletion
return {
  'saghen/blink.cmp',
  enabled = true,
  lazy = true,
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    'zbirenbaum/copilot.lua',
    'giuxtaposition/blink-cmp-copilot',
  },
  version = '*',
  opts = {
    keymap = { preset = 'default' },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
      kind_icons = {
        Copilot = '',
      },
    },
    completion = {
      menu = {
        draw = {
          columns = {
            { 'label', 'label_description', gap = 1 },
            { 'kind_icon', 'kind', gap = 1 },
          },
        },
      },
      documentation = { auto_show = true, auto_show_delay_ms = 500 },
      ghost_text = { enabled = true },
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
      default = { 'luasnip', 'lsp', 'buffer', 'copilot', 'path' },
      providers = {
        luasnip = {
          score_offset = 1,
        },
        copilot = {
          name = 'Copilot',
          module = 'blink-cmp-copilot',
          enabled = true,
          score_offset = -1,
          async = true,
          transform_items = function(_, items)
            local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
            local kind_idx = #CompletionItemKind + 1
            CompletionItemKind[kind_idx] = 'Copilot'
            for _, item in ipairs(items) do
              item.kind = kind_idx
            end
            return items
          end,
        },
      },
    },
    signature = { enabled = true },
  },
  opts_extend = { 'sources.default' },
}
