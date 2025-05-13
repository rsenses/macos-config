return {
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = { preset = 'default' },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = { documentation = { auto_show = true } },

    snippets = { preset = 'luasnip' },

    sources = {
      default = { 'snippets', 'lsp', 'path', 'buffer', 'lazydev' },
      providers = {
        snippets = {
          score_offset = 1000,
        },
        lsp = {
          score_offset = 100,
        },
        path = {
          score_offset = 10,
        },
        buffer = {
          opts = {
            -- filter to only "normal" buffers
            get_bufnrs = function()
              return vim.tbl_filter(function(bufnr)
                return vim.bo[bufnr].buftype == ''
              end, vim.api.nvim_list_bufs())
            end,
          },
          score_offset = 0,
        },
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },

    fuzzy = { implementation = 'prefer_rust_with_warning' },

    signature = { enabled = false },
  },
  opts_extend = { 'sources.default' },
}
